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
## SOURCE: transcribed from the Glosaryo (pp. 376-377) of the DepEd Grade 3
## Bikol MTB-MLE learner's material (Bamba et al., 2014) - photographed and
## sent in chat on 2026-09-27. Definitions are kept in Bikol exactly as
## printed, not translated to Tagalog, since that is how the source book
## itself defines each word.
##
## VERIFIED (2026-09-27) against the printed book for: IHIRAS's part of
## speech and meaning, KABAING, GIAN, DAPOG (its two senses are joined by
## "o", i.e. one word with two meanings, not a transcription error),
## MASARIGAN, MATAGOK, and UKA.
##
## STILL UNCONFIRMED - please double-check against the book:
##   - IHIRAS: the last word of its example sentence was hard to read in the
##     photo ("dahil sa kasulo" or something close to it).
##
## Three words (BADANG, BALUKAG, BUTBOTKUWAW) already have a recorded
## pronunciation because they are also used in the Campaign Map levels, so
## those reuse that same recording here.
const ENTRIES: Array = [
	{"word": "ATANG", "meaning": "Dulot; offering.", "cultural_note": "", "audio": ""},
	{"word": "ATANGAN", "meaning": "Lugar na pigbubugtakan nin atang.", "cultural_note": "", "audio": ""},
	{"word": "BADANG", "meaning": "Kahiwasan; meadow.", "cultural_note": "", "audio": "BADANG.mp3"},
	{"word": "BALUKAG", "meaning": "Barahibo; feathers.", "cultural_note": "Halimbawa: balukag nin manok, balukag nin gamgam.", "audio": "BALUKAG.mp3"},
	{"word": "BUTBOTKUWAW", "meaning": "Sarong klase nin gamgam; owl.", "cultural_note": "", "audio": "BUTBOTKUWAW.mp3"},
	{"word": "DANAW", "meaning": "Sarong klase nin anyong tubig.", "cultural_note": "", "audio": ""},
	{"word": "DAPOG", "meaning": "Mga pananom na paroy o mga dahon na pambulong na pigtapal sa apektadong lugar kan hawak.", "cultural_note": "", "audio": ""},
	{"word": "GIAN", "meaning": "Klase nin gabat.", "cultural_note": "Halimbawa: Magian an balukag kaysa sa sarong kilong bagas.", "audio": ""},
	{"word": "IHIRAS", "meaning": "Share.", "cultural_note": "Halimbawa: Ihiras mo an sobra mong balon na tinapay sa mga mayong balon para makakakan man sinda. Dapat tang ihiras an mga dai ta ginagamit na bado sa mga taong nawaraan nin gamit dahil sa kasulo.", "audio": ""},
	{"word": "KABAING", "meaning": "Kapareho.", "cultural_note": "", "audio": ""},
	{"word": "KAGIAN", "meaning": "Pareho an gabat.", "cultural_note": "", "audio": ""},
	{"word": "KANSYON", "meaning": "Kanta.", "cultural_note": "", "audio": ""},
	{"word": "KASAGKURAN", "meaning": "Hangganan; kataposan.", "cultural_note": "", "audio": ""},
	{"word": "KUBLIT", "meaning": "Skin.", "cultural_note": "", "audio": ""},
	{"word": "LADO", "meaning": "Parte.", "cultural_note": "", "audio": ""},
	{"word": "LALAG", "meaning": "Wild animal.", "cultural_note": "", "audio": ""},
	{"word": "LAOMAN", "meaning": "Kulongan.", "cultural_note": "", "audio": ""},
	{"word": "LIBOD", "meaning": "Lugar sa likod na parte kan harong.", "cultural_note": "", "audio": ""},
	{"word": "MABARIBI", "meaning": "Lalaganan nin tubig an tinanom; mabubo nin tinanom.", "cultural_note": "", "audio": ""},
	{"word": "MALANGKAG", "meaning": "Nahahaloyan na sa paghalat.", "cultural_note": "", "audio": ""},
	{"word": "NANTANG", "meaning": "While.", "cultural_note": "", "audio": ""},
	{"word": "NAPADARUSAY", "meaning": "Matumba; patihaya; slide.", "cultural_note": "", "audio": ""},
	{"word": "MASARIGAN", "meaning": "Masandigan; inaasahan; to depend on.", "cultural_note": "", "audio": ""},
	{"word": "MATAGOK", "meaning": "Juicy.", "cultural_note": "", "audio": ""},
	{"word": "NAGMUKNA", "meaning": "Nagpoon; naggibo.", "cultural_note": "", "audio": ""},
	{"word": "NAKAKAPAHUYOM", "meaning": "Nakakapangirit.", "cultural_note": "", "audio": ""},
	{"word": "NATAD", "meaning": "Lugar sa atubangan kan harong.", "cultural_note": "", "audio": ""},
	{"word": "NGUHOD", "meaning": "Bunsong tugang.", "cultural_note": "", "audio": ""},
	{"word": "PIGHIHIRAS", "meaning": "Pigsi-share; pigtataong tabang.", "cultural_note": "", "audio": ""},
	{"word": "RARAMASON", "meaning": "Mamasahon.", "cultural_note": "", "audio": ""},
	{"word": "RIGADERA", "meaning": "Sarong klase nin container na ginagamit na pambubo o pambaribi nin tinanom.", "cultural_note": "", "audio": ""},
	{"word": "SARIG", "meaning": "Matatag; matibay.", "cultural_note": "", "audio": ""},
	{"word": "TAGOK", "meaning": "Juice.", "cultural_note": "", "audio": ""},
	{"word": "UKA", "meaning": "Gatak kan daga.", "cultural_note": "", "audio": ""},
]
