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
##
## SOURCE: replaced in full with every entry of "Word of the day.docx"
## (sent 2026-10-22). Syllables, part of speech and meaning are taken exactly
## as typed there (only the first letter capitalised and a period added).
## English meanings were changed to Tagalog (2026-10-23) so pupils read only
## Tagalog or Bikol on the card.
const ENTRIES: Array = [
	{"word": "ATANG", "syllables": "a-ta-ng", "part_of_speech": "pangngaran", "meaning": "Dulot; alay o handog."},
	{"word": "ATANGAN", "syllables": "a-ta-ngan", "part_of_speech": "pangngaran", "meaning": "Lugar kun sain pigbubugtak an atang."},
	{"word": "BADANG", "syllables": "ba-dang", "part_of_speech": "pangngaran", "meaning": "Kahiwasan; malawak na damuhan."},
	{"word": "BALUKAG", "syllables": "ba-lu-kag", "part_of_speech": "pangngaran", "meaning": "Garahibo; balahibo ng ibon."},
	{"word": "BUTBOTKUWAW", "syllables": "but-bot-ku-waw", "part_of_speech": "pangngaran", "meaning": "Sarong klase nin gamgam; kuwago."},
	{"word": "DANAW", "syllables": "da-naw", "part_of_speech": "pangngaran", "meaning": "Sarong klase nin anyong tubig."},
	{"word": "DAPOG", "syllables": "da-pog", "part_of_speech": "pangngaran", "meaning": "Mga pananom na paroy, mga dahon na pambulong na pigtapal sa apektadong lugar kan hawak."},
	{"word": "GIAN", "syllables": "gi-an", "part_of_speech": "pang-uri", "meaning": "Klase nin gabat."},
	{"word": "IHIRAS", "syllables": "i-hi-ras", "part_of_speech": "pandiwa", "meaning": "Ibahagi; hatian ang iba."},
	{"word": "KABAING", "syllables": "ka-ba-ing", "part_of_speech": "", "meaning": "Kapareho."},
	{"word": "KAGIAN", "syllables": "ka-gi-an", "part_of_speech": "pang-uri", "meaning": "Pareho an gabat."},
	{"word": "KANSYON", "syllables": "kan-syon", "part_of_speech": "pangngaran", "meaning": "Kanta."},
	{"word": "KASAGKURAN", "syllables": "kasagkuran", "part_of_speech": "pangngaran", "meaning": "Hangganan, katapusan."},
	{"word": "KUBLIT", "syllables": "kub-lit", "part_of_speech": "pangngaran", "meaning": "Balat."},
	{"word": "LADO", "syllables": "la-do", "part_of_speech": "pangngaran", "meaning": "Parte."},
	{"word": "LALAG", "syllables": "la-lag", "part_of_speech": "pang-uri", "meaning": "Mailap o ligaw na hayop."},
	{"word": "LAOMAN", "syllables": "la-o-man", "part_of_speech": "pangngaran", "meaning": "Kulongan."},
	{"word": "LIBOD", "syllables": "li-bod", "part_of_speech": "pangngaran", "meaning": "Lugar sa likod na parte kan harong."},
	{"word": "MABARIBI", "syllables": "ma-ba-ri-bi", "part_of_speech": "pandiwa", "meaning": "Lalagan nin tubig an tinanom, mabubo nin tinanom."},
	{"word": "MALANGKAG", "syllables": "ma-lang-kag", "part_of_speech": "pang-uri", "meaning": "Nahahaloyan na sa paghalat."},
	{"word": "MANTANG", "syllables": "man-tang", "part_of_speech": "", "meaning": "Habang."},
	{"word": "NAPADARUSAY", "syllables": "na-pa-da-ru-say", "part_of_speech": "pandiwa", "meaning": "Matumba patihaya; madulas."},
	{"word": "MASARIGAN", "syllables": "ma-sa-ri-gan", "part_of_speech": "pang-uri", "meaning": "Masandigan; maaasahan."},
	{"word": "MATAGOK", "syllables": "ma-ta-gok", "part_of_speech": "pang-uri", "meaning": "Makatas."},
	{"word": "NAGMUKNA", "syllables": "nag-muk-na", "part_of_speech": "pandiwa", "meaning": "Nagpoon, naggibo."},
	{"word": "NAKAKAPAHUYOM", "syllables": "na-ka-ka-pa-hu-yom", "part_of_speech": "pandiwa", "meaning": "Nakakapangirit."},
	{"word": "NATAD", "syllables": "na-tad", "part_of_speech": "pangngaran", "meaning": "Lugar sa atubangan kan harong."},
	{"word": "NGUHOD", "syllables": "ngu-hod", "part_of_speech": "pangngaran", "meaning": "Bunsong tugang."},
	{"word": "PIGHIHIRAS", "syllables": "pig-hi-hi-ras", "part_of_speech": "pandiwa", "meaning": "Ibinabahagi; pigtatong tabang."},
	{"word": "RARAMASON", "syllables": "ra-ra-ma-son", "part_of_speech": "pandiwa", "meaning": "Mamasahon."},
	{"word": "RIGADERA", "syllables": "ri-ga-de-ra", "part_of_speech": "pangngaran", "meaning": "Sarong klase nin container na ginagamit na pambubo o pambaribi nin tinanom."},
	{"word": "SARIG", "syllables": "sa-rig", "part_of_speech": "pang-uri", "meaning": "Matatag, matibay."},
	{"word": "TAGOK", "syllables": "ta-gok", "part_of_speech": "pangngaran", "meaning": "Katas."},
	{"word": "UKA", "syllables": "u-ka", "part_of_speech": "pangngaran", "meaning": "Gatok kan daga."},
]
