extends RefCounted
## Glosaryo - the pool of words shown by "Salita Ngayong Araw" (Word of the Day).
##
## Every calendar day the game picks the next entry from ENTRIES (Monday one
## word, Tuesday the next, ...). It is bundled inside the app, so the Word of
## the Day works with no internet at all.
##
## Each entry is a Dictionary:
##   "word":           the Bikol-Partido word                      (required)
##   "syllables":      the word split into syllables, e.g. "ba-dang" (optional - "" hides it)
##   "part_of_speech": pangngaran / pang-uri / pandiwa             (optional)
##   "meaning":        its meaning/definition (kahulugan)          (required)
##   "cultural_note":  a short note or example sentence            (optional - "" hides it)
##
## SOURCE: replaced in full with every entry of "Word of the day.docx"
## (sent 2026-10-22). Syllables, part of speech and meaning are taken exactly
## as typed there (only the first letter capitalised and a period added).
## That document has no example sentences, so the three "Halimbawa" notes
## from the earlier Glosaryo_Typed_COMPLETE.docx are kept as cultural notes.
const ENTRIES: Array = [
	{"word": "ATANG", "syllables": "a-ta-ng", "part_of_speech": "pangngaran", "meaning": "Dulot, offering.", "cultural_note": ""},
	{"word": "ATANGAN", "syllables": "a-ta-ngan", "part_of_speech": "pangngaran", "meaning": "Lugar kun sain pigbubugtak an atang.", "cultural_note": ""},
	{"word": "BADANG", "syllables": "ba-dang", "part_of_speech": "pangngaran", "meaning": "Kahinwasan, meadow.", "cultural_note": ""},
	{"word": "BALUKAG", "syllables": "ba-lu-kag", "part_of_speech": "pangngaran", "meaning": "Garahibo, feathers.", "cultural_note": "Halimbawa: balukag nin manok, balukag nin gamgam."},
	{"word": "BUTBOTKUWAW", "syllables": "but-bot-ku-waw", "part_of_speech": "pangngaran", "meaning": "Sarong klase nin gamgam, owl.", "cultural_note": ""},
	{"word": "DANAW", "syllables": "da-naw", "part_of_speech": "pangngaran", "meaning": "Sarong klase nin anyong tubig.", "cultural_note": ""},
	{"word": "DAPOG", "syllables": "da-pog", "part_of_speech": "pangngaran", "meaning": "Mga pananom na paroy, mga dahon na pambulong na pigtapal sa apektadong lugar kan hawak.", "cultural_note": ""},
	{"word": "GIAN", "syllables": "gi-an", "part_of_speech": "pang-uri", "meaning": "Klase nin gabat.", "cultural_note": "Halimbawa: Magian an balukag kaysa sa sarong kilong bagas."},
	{"word": "IHIRAS", "syllables": "i-hi-ras", "part_of_speech": "pandiwa", "meaning": "Share.", "cultural_note": "Halimbawa: Ihiras mo an sobra mong balon na tinapay sa mga mayong balon para makadakan man sinda. Dapat tang ihiras an mga dai tang ginagamit na bado sa mga taong nawaraan nin gamit dahil sa kasulo."},
	{"word": "KABAING", "syllables": "ka-ba-ing", "part_of_speech": "", "meaning": "Kapareho.", "cultural_note": ""},
	{"word": "KAGIAN", "syllables": "ka-gi-an", "part_of_speech": "pang-uri", "meaning": "Pareho an gabat.", "cultural_note": ""},
	{"word": "KANSYON", "syllables": "kan-syon", "part_of_speech": "pangngaran", "meaning": "Kanta.", "cultural_note": ""},
	{"word": "KASAGKURAN", "syllables": "kasagkuran", "part_of_speech": "pangngaran", "meaning": "Hangganan, katapusan.", "cultural_note": ""},
	{"word": "KUBLIT", "syllables": "kub-lit", "part_of_speech": "pangngaran", "meaning": "Skin.", "cultural_note": ""},
	{"word": "LADO", "syllables": "la-do", "part_of_speech": "pangngaran", "meaning": "Parte.", "cultural_note": ""},
	{"word": "LALAG", "syllables": "la-lag", "part_of_speech": "pang-uri", "meaning": "Wild animal.", "cultural_note": ""},
	{"word": "LAOMAN", "syllables": "la-o-man", "part_of_speech": "pangngaran", "meaning": "Kulongan.", "cultural_note": ""},
	{"word": "LIBOD", "syllables": "li-bod", "part_of_speech": "pangngaran", "meaning": "Lugar sa likod na parte kan harong.", "cultural_note": ""},
	{"word": "MABARIBI", "syllables": "ma-ba-ri-bi", "part_of_speech": "pandiwa", "meaning": "Lalagan nin tubig an tinanom, mabubo nin tinanom.", "cultural_note": ""},
	{"word": "MALANGKAG", "syllables": "ma-lang-kag", "part_of_speech": "pang-uri", "meaning": "Nahahaloyan na sa paghalat.", "cultural_note": ""},
	{"word": "MANTANG", "syllables": "man-tang", "part_of_speech": "", "meaning": "While.", "cultural_note": ""},
	{"word": "NAPADARUSAY", "syllables": "na-pa-da-ru-say", "part_of_speech": "pandiwa", "meaning": "Matumba patihaya, slide.", "cultural_note": ""},
	{"word": "MASARIGAN", "syllables": "ma-sa-ri-gan", "part_of_speech": "pang-uri", "meaning": "Masandigan, inaasahan, to depend on.", "cultural_note": ""},
	{"word": "MATAGOK", "syllables": "ma-ta-gok", "part_of_speech": "pang-uri", "meaning": "Juicy.", "cultural_note": ""},
	{"word": "NAGMUKNA", "syllables": "nag-muk-na", "part_of_speech": "pandiwa", "meaning": "Nagpoon, naggibo.", "cultural_note": ""},
	{"word": "NAKAKAPAHUYOM", "syllables": "na-ka-ka-pa-hu-yom", "part_of_speech": "pandiwa", "meaning": "Nakakapangirit.", "cultural_note": ""},
	{"word": "NATAD", "syllables": "na-tad", "part_of_speech": "pangngaran", "meaning": "Lugar sa atubangan kan harong.", "cultural_note": ""},
	{"word": "NGUHOD", "syllables": "ngu-hod", "part_of_speech": "pangngaran", "meaning": "Bunsong tugang.", "cultural_note": ""},
	{"word": "PIGHIHIRAS", "syllables": "pig-hi-hi-ras", "part_of_speech": "pandiwa", "meaning": "Pigi-share, pigtatong tabang.", "cultural_note": ""},
	{"word": "RARAMASON", "syllables": "ra-ra-ma-son", "part_of_speech": "pandiwa", "meaning": "Mamasahon.", "cultural_note": ""},
	{"word": "RIGADERA", "syllables": "ri-ga-de-ra", "part_of_speech": "pangngaran", "meaning": "Sarong klase nin container na ginagamit na pambubo o pambaribi nin tinanom.", "cultural_note": ""},
	{"word": "SARIG", "syllables": "sa-rig", "part_of_speech": "pang-uri", "meaning": "Matatag, matibay.", "cultural_note": ""},
	{"word": "TAGOK", "syllables": "ta-gok", "part_of_speech": "pangngaran", "meaning": "Juice.", "cultural_note": ""},
	{"word": "UKA", "syllables": "u-ka", "part_of_speech": "pangngaran", "meaning": "Gatok kan daga.", "cultural_note": ""},
]
