class_name PDFReportGenerator
extends RefCounted

## Dependency-free PDF 1.4 writer used by the Teacher Dashboard's
## "Download Report" button (Leaderboard page). No external libraries,
## no embedded fonts/images/compression - just Helvetica text objects -
## so the whole file is built as one plain WinAnsi/Latin-1 String and
## converted to bytes one character at a time at the very end. That
## keeps every xref byte-offset exactly equal to the String length at
## the point it was recorded, with no separate byte-buffer bookkeeping.

const PAGE_WIDTH := 612.0
const PAGE_HEIGHT := 792.0
const MARGIN := 50.0
const ROWS_PER_PAGE := 32

## rows: Array[Dictionary] already computed by the caller, each with
## "rank", "name", "level", "stars" - this script only lays them out.
static func build_class_report(teacher_name: String, school_name: String, class_name_text: String, grade_subject: String, class_code: String, generated_on: String, total_students: int, active_students: int, rows: Array) -> PackedByteArray:
	var row_chunks: Array = []
	if rows.is_empty():
		row_chunks.append([])
	else:
		var i := 0
		while i < rows.size():
			row_chunks.append(rows.slice(i, min(i + ROWS_PER_PAGE, rows.size())))
			i += ROWS_PER_PAGE

	var catalog_obj := 1
	var pages_obj := 2
	var font_obj := 3
	var font_bold_obj := 4
	var next_obj := 5
	var page_obj_nums: Array[int] = []
	var content_obj_nums: Array[int] = []
	for p in range(row_chunks.size()):
		page_obj_nums.append(next_obj); next_obj += 1
		content_obj_nums.append(next_obj); next_obj += 1

	var objects: Array[String] = []
	objects.resize(next_obj - 1)

	var kids := ""
	for n in page_obj_nums:
		kids += "%d 0 R " % n
	objects[pages_obj - 1] = "<< /Type /Pages /Kids [%s] /Count %d >>" % [kids.strip_edges(), page_obj_nums.size()]
	objects[catalog_obj - 1] = "<< /Type /Catalog /Pages %d 0 R >>" % pages_obj
	objects[font_obj - 1] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
	objects[font_bold_obj - 1] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"

	for p in range(row_chunks.size()):
		var content := _build_page_content(teacher_name, school_name, class_name_text, grade_subject, class_code, generated_on, total_students, active_students, row_chunks[p], p + 1, row_chunks.size(), rows.is_empty())
		objects[content_obj_nums[p] - 1] = "<< /Length %d >>\nstream\n%s\nendstream" % [content.length(), content]
		objects[page_obj_nums[p] - 1] = "<< /Type /Page /Parent %d 0 R /MediaBox [0 0 %d %d] /Resources << /Font << /F1 %d 0 R /F2 %d 0 R >> >> /Contents %d 0 R >>" % [pages_obj, int(PAGE_WIDTH), int(PAGE_HEIGHT), font_obj, font_bold_obj, content_obj_nums[p]]

	var pdf := "%PDF-1.4\n"
	var offsets: Array[int] = []
	offsets.resize(objects.size())
	for i in range(objects.size()):
		offsets[i] = pdf.length()
		pdf += "%d 0 obj\n%s\nendobj\n" % [i + 1, objects[i]]

	var xref_offset := pdf.length()
	pdf += "xref\n0 %d\n" % (objects.size() + 1)
	pdf += "0000000000 65535 f \n"
	for off in offsets:
		pdf += "%010d 00000 n \n" % off
	pdf += "trailer\n<< /Size %d /Root %d 0 R >>\nstartxref\n%d\n%%%%EOF" % [objects.size() + 1, catalog_obj, xref_offset]

	return _to_latin1_bytes(pdf)

static func _build_page_content(teacher_name: String, school_name: String, class_name_text: String, grade_subject: String, class_code: String, generated_on: String, total_students: int, active_students: int, rows: Array, page_num: int, page_count: int, is_empty: bool) -> String:
	var y := PAGE_HEIGHT - MARGIN
	var content := ""

	if page_num == 1:
		content += _text(MARGIN, y, "F2", 20, "Partido Word-Catch - Class Report")
		y -= 26
		content += _text(MARGIN, y, "F1", 11, "Teacher: %s" % teacher_name)
		y -= 16
		if school_name != "":
			content += _text(MARGIN, y, "F1", 11, "School: %s" % school_name)
			y -= 16
		var class_line := class_name_text if class_name_text != "" else grade_subject
		if class_line != "":
			content += _text(MARGIN, y, "F1", 11, "Class: %s" % class_line)
			y -= 16
		content += _text(MARGIN, y, "F1", 11, "Class Code: %s" % class_code)
		y -= 16
		content += _text(MARGIN, y, "F1", 11, "Generated: %s" % generated_on)
		y -= 16
		content += _text(MARGIN, y, "F1", 11, "Total Students: %d      Active in last 24h: %d" % [total_students, active_students])
		y -= 24
	else:
		content += _text(MARGIN, y, "F2", 14, "Partido Word-Catch - Class Report (continued)")
		y -= 26

	if is_empty:
		content += _text(MARGIN, y, "F1", 11, "No students have joined this class yet.")
	else:
		content += _text(MARGIN, y, "F2", 11, "Rank")
		content += _text(MARGIN + 60, y, "F2", 11, "Name")
		content += _text(MARGIN + 320, y, "F2", 11, "Level")
		content += _text(MARGIN + 400, y, "F2", 11, "Stars")
		y -= 6
		content += "%0.2f %0.2f m %0.2f %0.2f l S\n" % [MARGIN, y, PAGE_WIDTH - MARGIN, y]
		y -= 16
		for row in rows:
			content += _text(MARGIN, y, "F1", 10, str(row.rank))
			content += _text(MARGIN + 60, y, "F1", 10, str(row.name))
			content += _text(MARGIN + 320, y, "F1", 10, "Level " + str(row.level))
			content += _text(MARGIN + 400, y, "F1", 10, str(row.stars))
			y -= 18
			if y < MARGIN + 20:
				break

	content += _text(PAGE_WIDTH - MARGIN - 70, MARGIN - 20, "F1", 9, "Page %d of %d" % [page_num, page_count])
	return content

static func _text(x: float, y: float, font_key: String, font_size: int, value: String) -> String:
	return "BT /%s %d Tf %0.2f %0.2f Td (%s) Tj ET\n" % [font_key, font_size, x, y, _escape(value)]

static func _escape(s: String) -> String:
	return s.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")

static func _to_latin1_bytes(text: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(text.length())
	for i in range(text.length()):
		var code := text.unicode_at(i)
		bytes[i] = code if code <= 255 else 63
	return bytes
