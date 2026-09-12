extends Node

var levels = {
	1: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "IDO",
		"clue": "Ito ay alagang hayop na kilala sa pagiging tapat sa tao.",
		"audio": "IDO.mp3",
		"meaning": "Aso sa wikang Bikol.",
		"cultural_note": "Ang 'ido' ay itinuturing na matalik na kaibigan at tagapag-bantay ng tahanan sa pamilyang Bikolano."
	},
	2: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "UMA",
		"clue": "Ito ay lupang tinataniman ng palay, gulay, o iba pang pananim.",
		"audio": "UMA.mp3",
		"meaning": "Bukid o sakahan.",
		"cultural_note": "Ang 'uma' ang pangunahing pinagkukunan ng kabuhayan ng maraming pamilya sa kabikolan."
	},
	3: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "IKOS",
		"clue": "Ito ay alagang hayop na mahilig manghuli ng daga at karaniwang umuungol ng 'meow'.",
		"audio": "IKOS.mp3",
		"meaning": "Pusa sa wikang Bikol.",
		"cultural_note": "Karaniwang alaga ang 'ikos' sa mga bahay upang magbantay laban sa mga peste."
	},
	4: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "APOD",
		"clue": "Ito ay tawag o bansag na ginagamit sa isang tao.",
		"audio": "APOD.mp3",
		"meaning": "Tawag o pagtawag sa pangalan ng tao.",
		"cultural_note": "Mahalaga ang 'apod' o pagtawag nang may paggalang tulad ng paggamit ng 'Noy' o 'Nay'."
	},
	5: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "UKAG",
		"clue": "Ito ay paghahalo ng dalawa o higit pang bagay.",
		"audio": "UKAG.mp3",
		"meaning": "Paghahalo o paggulo sa mga bagay.",
		"cultural_note": "Karaniwang ginagamit kapag naghahalo ng mga sangkap sa pagluluto ng pagkaing Bikolano."
	},
	6: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "BURAK",
		"clue": "Ito ay bahagi ng halaman na may iba't ibang kulay at amoy.",
		"audio": "BURAK.mp3",
		"meaning": "Bulaklak sa wikang Bikol.",
		"cultural_note": "Ginagamit ang mga 'burak' sa mga kapistahan at pag-aalay sa mga simbahan sa Bicol."
	},
	7: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "KATRE",
		"clue": "Ito ay gamit sa bahay na pinaghihigaan kapag natutulog o nagpapahinga.",
		"audio": "KATRE.mp3",
		"meaning": "Kama o tulugan.",
		"cultural_note": "Simbolo ng pahinga ng pamilya matapos ang buong araw na pagtatrabaho."
	},
	8: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "BAYLE",
		"clue": "Ito ay pagsayaw kasabay ng musika.",
		"audio": "BAYLE.mp3",
		"meaning": "Sayaw o pampublikong pasayaw.",
		"cultural_note": "Ang 'bayle' ay isang sikat na tradisyon sa mga baryo tuwing may kapistahan."
	},
	9: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "GAKOD",
		"clue": "Ito ay ginagamit sa pagtali ng mga bagay o hayop.",
		"audio": "GAKOD.mp3",
		"meaning": "Tali o pagtatali.",
		"cultural_note": "Ginagamit ng mga mangingisda at magsasaka upang i-gaya/isara ang kanilang mga kagamitan."
	},
	10: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "BADANG",
		"clue": "Ito ay malawak na damuhan o parang.",
		"audio": "BADANG.mp3",
		"meaning": "Tulong o saklolo.",
		"cultural_note": "Nagpapakita ng espiritu ng Bayanihan o pagtutulungan ng mga kapitbahay."
	},
	11: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "DAMULAG",
		"clue": "Isa itong malaking hayop na tumutulong sa pagsasaka.",
		"audio": "DAMULAG.mp3",
		"meaning": "Kalabaw sa wikang Bikol.",
		"cultural_note": "Ang 'damulag' ang pambansang simbolo ng sipag at tiyaga ng mga magsasakang Bikolano."
	},
	12: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "BALUKAG",
		"clue": "Ito ang balahibo ng mga ibon o manok na nagbibigay ng proteksyon.",
		"audio": "BALUKAG.mp3",
		"meaning": "Balahibo ng ibon o manok.",
		"cultural_note": "Ginagamit din ang salitang ito kapag sinasabing 'nagpapatayo ng balukag' (pangingilabot)."
	},
	13: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "MARIKAS",
		"clue": "Ito ay taong o bagay na kumikilos nang mabilis.",
		"audio": "MARIKAS.mp3",
		"meaning": "Mabilis o matulin.",
		"cultural_note": "Inilalarawan ang isang taong maagap at mabilis gumawa ng mga gawaing-bahay."
	},
	14: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "MAKUSOG",
		"clue": "Ito ay taong may malakas na katawan o lakas.",
		"audio": "MAKUSOG.mp3",
		"meaning": "Malakas o matatag.",
		"cultural_note": "Isang katangian ng mga Bikolano na matatag sa anumang pagsubok o bagyo."
	},
	15: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "MAGAYON",
		"clue": "Ito ay paglalarawan sa isang tao, bagay, o lugar na kaaya-aya sa paningin.",
		"audio": "MAGAYON.mp3",
		"meaning": "Maganda sa wikang Bikol.",
		"cultural_note": "Hango sa alamat ni 'Daragang Magayon' kung saan nagmula ang Bulkang Mayon."
	},
	16: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "NAGSAKAT",
		"clue": "Ito ay pag-akyat sa puno, bundok, hagdan, o mataas na lugar.",
		"audio": "NAGSAKAT.mp3",
		"meaning": "pag akyat o umakyat.",
		"cultural_note": "Karaniwang ginagamit sa paglalarawan ng pag-akyat sa puno ng niyog."
	},
	17: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "NAGSAKDO",
		"clue": "Ito ay pagkuha ng tubig mula sa balon o lalagyan gamit ang timba.",
		"audio": "NAGSAKDO.mp3",
		"meaning": "Pagsalok o pagkuha ng tubig.",
		"cultural_note": "Isang nakagawiang gawaing pang-araw-araw sa mga nayon kung saan ang mga kabataan o magulang ay pumupunta sa balon."
	},
	18: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "NAGLALAKAW",
		"clue": "Ito ay kilos o galaw ng pag-usad pasulong gamit ang mga paa.",
		"audio": "NAGLALAKAW.mp3",
		"meaning": "Pag-usad o pagpapatuloy sa pag-hakbang.",
		"cultural_note": "Sumisimbolo sa matiyagang paghakbang at pagtahak ng mga Bikolano sa kanilang pang-araw-araw na paglalakbay sa buhay."
	},
	19: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "NAGKURAHAW",
		"clue": "Ito ay pagsigaw nang malakas upang marinig ng iba.",
		"audio": "NAGKURAHAW.mp3",
		"meaning": "Paghiyaw o pagtawag nang malakas.",
		"cultural_note": "Karaniwang ginagamit sa mga kwentong bayan kapag may ibinabalita o binabalaan ang mga kabaryo mula sa malayo."
	},
	20: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "BUTBOTKUWAW",
		"clue": "Isa itong ibon na gising sa gabi.",
		"audio": "BUTBOTKUWAW.mp3",
		"meaning": "Kuwago (Owl).",
		"cultural_note": "Sa mga kwentong bayan, inuugnay ang kwago sa mga kwentong kababalaghan sa gabi."
	},
	21: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "MAGANA NGUNYAN MAGKAKAN SI PAULO",
		"clue": "Malakas kumain si Paulo ngayon.",
		"meaning": "Magana ngayon si Paulo.",
		"cultural_note": "Karaniwang ekspresyon sa pagkain o pag napaparami tayong kain.",
		"audio": "21.mp3"
	},
	22: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "DAKUL AN DAKOP NI TIYO SAMMY",
		"clue": "Marami ang huli ni Tiyo Sammy.",
		"meaning": "Maraming nahuli si Tiyo Sammy.",
		"cultural_note": "Ang mga mangingisda ay kadalasan maraming huli mensan naman ay kunti.",
		"audio": "22.mp3"
	},
	23: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "BUROBANGGI SIYANG NAGSUSULO NIN KIRAY",
		"clue": "Gabi-gabi siyang nagpupuyat para mag-aral.",
		"meaning": "Puyat nang puyat siya tuwing gabi.",
		"cultural_note": "Nagsusulo ay nangangahulugang nagpupuyat o pagiging gising sa gabi.",
		"audio": "23.mp3"
	},
	24: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "KADAKUL AN NAGDADALAN SA PALABAS NA INI",
		"clue": "Marami ang nanonood sa palabas na ito.",
		"meaning": "Maraming nanonood sa palabas na ito.",
		"cultural_note": "Pag maganda ang palabas ay nakasanayan nang manood ng sabay sabay.",
		"audio": "24.mp3"
	},
	25: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "IGWA SA LUGAR NINDANG MAY HALABANG KAMAY",
		"clue": "Mayroon sa lugar nila na mahaba ang kamay.",
		"meaning": "May taong mahaba ang kamot sa lugar nila.",
		"cultural_note": "Idyoma para sa magnanakaw or mga taong nangunguha ng hindi sakanila.",
		"audio": "25.mp3"
	},
	26: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "URO-ATYAN MADUMAN KAMI SA MUNISIPYO",
		"clue": "Mamaya-maya, pupunta kami sa munisipyo.",
		"meaning": "Mamaya ay pupunta kami sa munisipyo.",
		"cultural_note": "Uro-atyan ang ibig sabihin ay mamaya-maya.",
		"audio": "26.mp3"
	},
	27: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "NAGDADALAN SI MARCO NIN TELENOBELA SA TELEBISYON",
		"clue": "Nanood si Marco ng telenovela sa telebisyon.",
		"meaning": "Nanood si Marco ng telenobela.",
		"cultural_note": "Nakagawian na natin ang panonood ng telenobela sa telebisyon.",
		"audio": "27.mp3"
	},
	28: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "URO-UTRO NIYANG TIGSABI AN SAKUYANG PANGARAN",
		"clue": "Paulit-ulit niyang sinasabi ang aking pangalan.",
		"meaning": "Paulit-ulit niyang binabanggit ang pangalan ko.",
		"cultural_note": "Uro-utro ay ibig sabihin paulit-ulit na lagi nating ginagawa.",
		"audio": "28.mp3"
	},
	29: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "MAHAMIS AN DILA NI LITA KAYA DAKUL AN NAIPABAKAL NIYA",
		"clue": "Matamis ang dila ni Lita kaya marami siyang naibenta.",
		"meaning": "Magaling magsalita si Lita kaya marami siyang nabenta.",
		"cultural_note": "Ang pagkakaroon ng matamis na dila ay magaling manghikayat o mag pasaya ng tao.",
		"audio": "29.mp3"
	},
	30: {
		"unit": "Yunit 5: Mga Pangungusap",
		"word": "NAGBIBISITA AN SAMUYANG PAMILYA SA BANWAAN KAN PILI KADA TAON",
		"clue": "Bumibisita ang aming pamilya sa bayan ng Pili taon-taon.",
		"meaning": "Dumadalaw ang pamilya namin sa Pili taon-taon.",
		"cultural_note": "Nakagawian na nilang na taon-taon ang pagbisita sa Pili.",
		"audio": "30.mp3"
	}
}
