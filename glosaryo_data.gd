extends RefCounted
## Glosaryo - the pool of words shown by "Salita Ngayong Araw" (Word of the Day).
##
## Every calendar day the game picks the next entry from ENTRIES (Monday one
## word, Tuesday the next, ...). It is bundled inside the app, so the Word of
## the Day works with no internet at all.
##
## Each entry is a Dictionary:
##   "word":          the Bikol-Partido word                      (required)
##   "meaning":       its meaning/definition (kahulugan)          (required)
##   "cultural_note": a short note or example sentence            (optional - "" hides it)
##   "audio":         file name of a recording inside res://audio/ (optional - "" hides the speaker)
##                    e.g. "APOD.mp3"
##
## SOURCE: replaced in full with the contents of Glosaryo_Typed_COMPLETE.docx
## (sent in chat 2026-09-30), the complete typed transcription of the
## Glosaryo from the DepEd Grade 3 Bikol MTB-MLE learner's material
## (Bamba et al., 2014). Every word/meaning below is taken exactly as typed
## in that document; nothing added or removed. Where a word has two listed
## meanings, both are kept, joined by "o" (matching how the source itself
## presents a single word with more than one sense, e.g. DAPOG).
##
## Three words (BADANG, BALUKAG, BUTBOTKUWAW) already have a recorded
## pronunciation because they are also used in the Campaign Map levels, so
## those reuse that same recording here.
const ENTRIES: Array = [
	{"word": "ATANG", "meaning": "Dulot; offering.", "cultural_note": "", "audio": ""},
	{"word": "ATANGAN", "meaning": "Lugar kun sain pigbubugtak an atang.", "cultural_note": "", "audio": ""},
	{"word": "BADANG", "meaning": "Kahinwasan; meadow.", "cultural_note": "", "audio": "BADANG.mp3"},
	{"word": "BALUKAG", "meaning": "Garahibo; feathers.", "cultural_note": "Halimbawa: balukag nin manok, balukag nin gamgam.", "audio": "BALUKAG.mp3"},
	{"word": "BUTBOTKUWAW", "meaning": "Sarong klase nin gamgam; owl.", "cultural_note": "", "audio": "BUTBOTKUWAW.mp3"},
	{"word": "DANAW", "meaning": "Sarong klase nin anyong tubig.", "cultural_note": "", "audio": ""},
	{"word": "DAPOG", "meaning": "Mga pananom na paroy o mga dahon na pambulong na pigtapal sa apektadong lugar kan hawak.", "cultural_note": "", "audio": ""},
	{"word": "GIAN", "meaning": "Klase nin gabat.", "cultural_note": "Halimbawa: Magian an balukag kaysa sa sarong kilong bagas.", "audio": ""},
	{"word": "IHIRAS", "meaning": "Share.", "cultural_note": "Halimbawa: Ihiras mo an sobra mong balon na tinapay sa mga mayong balon para makadakan man sinda. Dapat tang ihiras an mga dai tang ginagamit na bado sa mga taong nawaraan nin gamit dahil sa kasulo.", "audio": ""},
	{"word": "KABAING", "meaning": "Kapareho.", "cultural_note": "", "audio": ""},
	{"word": "KAGIAN", "meaning": "Pareho an gabat.", "cultural_note": "", "audio": ""},
	{"word": "KANSYON", "meaning": "Kanta.", "cultural_note": "", "audio": ""},
	{"word": "KASAGKURAN", "meaning": "Hangganan; katapusan.", "cultural_note": "", "audio": ""},
	{"word": "KUBLIT", "meaning": "Skin.", "cultural_note": "", "audio": ""},
	{"word": "LADO", "meaning": "Parte.", "cultural_note": "", "audio": ""},
	{"word": "LALAG", "meaning": "Wild animal.", "cultural_note": "", "audio": ""},
	{"word": "LAOMAN", "meaning": "Kulongan.", "cultural_note": "", "audio": ""},
	{"word": "LIBOD", "meaning": "Lugar sa likod na parte kan harong.", "cultural_note": "", "audio": ""},
	{"word": "MABARIBI", "meaning": "Lalagan nin tubig an tinanom o mabubo nin tinanom.", "cultural_note": "", "audio": ""},
	{"word": "MALANGKAG", "meaning": "Nahahagloyan na sa paghalat.", "cultural_note": "", "audio": ""},
	{"word": "NANTANG", "meaning": "While.", "cultural_note": "", "audio": ""},
	{"word": "NAPADARUSAY", "meaning": "Matumba patihaya o slide.", "cultural_note": "", "audio": ""},
	{"word": "NASARIGAN", "meaning": "Masandigan; inaasahan; to depend on.", "cultural_note": "", "audio": ""},
	{"word": "MATAGOK", "meaning": "Juicy.", "cultural_note": "", "audio": ""},
	{"word": "NAGMUKNA", "meaning": "Nagpoon; naggibo.", "cultural_note": "", "audio": ""},
	{"word": "NAKAKAPAHUYOM", "meaning": "Nakakapangirit.", "cultural_note": "", "audio": ""},
	{"word": "NATAD", "meaning": "Lugar sa atubangan kan harong.", "cultural_note": "", "audio": ""},
	{"word": "NGUHOD", "meaning": "Bunsong tugang.", "cultural_note": "", "audio": ""},
	{"word": "PIGHIHIRAS", "meaning": "Pigi-share o pigtatong tabang.", "cultural_note": "", "audio": ""},
	{"word": "RARAMASON", "meaning": "Mamasahon.", "cultural_note": "", "audio": ""},
	{"word": "RIGADERA", "meaning": "Sarong klase nin container na ginagamit na pambubo o pambiribi nin tinanom.", "cultural_note": "", "audio": ""},
	{"word": "SARIG", "meaning": "Matatag; matibay.", "cultural_note": "", "audio": ""},
	{"word": "TAGOK", "meaning": "Juice.", "cultural_note": "", "audio": ""},
	{"word": "UKA", "meaning": "Gatok kan daga.", "cultural_note": "", "audio": ""},
]
