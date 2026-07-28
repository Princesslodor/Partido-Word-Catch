extends Node

var levels = {
	1: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "IDO",
		"clue": "Ito ay alagang hayop na kilala sa pagiging tapat sa tao.",
		"audio": "ido.mp3",
		"meaning": "Aso sa wikang Bikol.",
		"cultural_note": "Ang 'ido' ay itinuturing na matalik na kaibigan at tagapag-bantay ng tahanan sa pamilyang Bikolano."
	},
	2: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "UMA",
		"clue": "Ito ay lupang tinataniman ng palay, gulay, o iba pang pananim.",
		"audio": "uma.mp3",
		"meaning": "Bukid o sakahan.",
		"cultural_note": "Ang 'uma' ang pangunahing pinagkukunan ng kabuhayan ng maraming pamilya sa kabikolan."
	},
	3: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "IKOS",
		"clue": "Ito ay alagang hayop na mahilig manghuli ng daga at karaniwang umuungol ng 'meow'.",
		"audio": "ikos.mp3",
		"meaning": "Pusa sa wikang Bikol.",
		"cultural_note": "Karaniwang alaga ang 'ikos' sa mga bahay upang magbantay laban sa mga peste."
	},
	4: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "APOD",
		"clue": "Ito ay tawag o bansag na ginagamit sa isang tao.",
		"audio": "apod.mp3",
		"meaning": "Tawag o pagtawag sa pangalan ng tao.",
		"cultural_note": "Mahalaga ang 'apod' o pagtawag nang may paggalang tulad ng paggamit ng 'Noy' o 'Nay'."
	},
	5: {
		"unit": "Yunit 1: Sarili at Pamilya",
		"word": "UKAG",
		"clue": "Ito ay paghahalo ng dalawa o higit pang bagay.",
		"audio": "ukag.mp3",
		"meaning": "Paghahalo o paggulo sa mga bagay.",
		"cultural_note": "Karaniwang ginagamit kapag naghahalo ng mga sangkap sa pagluluto ng pagkaing Bikolano."
	},
	6: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "BURAK",
		"clue": "Ito ay bahagi ng halaman na may iba't ibang kulay at amoy.",
		"audio": "burak.mp3",
		"meaning": "Bulaklak sa wikang Bikol.",
		"cultural_note": "Ginagamit ang mga 'burak' sa mga kapistahan at pag-aalay sa mga simbahan sa Bicol."
	},
	7: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "KATRE",
		"clue": "Ito ay gamit sa bahay na pinaghihigaan kapag natutulog o nagpapahinga.",
		"audio": "katre.mp3",
		"meaning": "Kama o tulugan.",
		"cultural_note": "Simbolo ng pahinga ng pamilya matapos ang buong araw na pagtatrabaho."
	},
	8: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "BAYLE",
		"clue": "Ito ay pagsayaw kasabay ng musika.",
		"audio": "bayle.mp3",
		"meaning": "Sayaw o pampublikong pasayaw.",
		"cultural_note": "Ang 'bayle' ay isang sikat na tradisyon sa mga baryo tuwing may kapistahan."
	},
	9: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "GAKOD",
		"clue": "Ito ay ginagamit sa pagtali ng mga bagay o hayop.",
		"audio": "gakod.mp3",
		"meaning": "Tali o pagtatali.",
		"cultural_note": "Ginagamit ng mga mangingisda at magsasaka upang i-gaya/isara ang kanilang mga kagamitan."
	},
	10: {
		"unit": "Yunit 2: Komunidad at Kalikasan",
		"word": "BADANG",
		"clue": "Ito ay malawak na damuhan o parang.",
		"audio": "badang.mp3",
		"meaning": "Tulong o saklolo.",
		"cultural_note": "Nagpapakita ng espiritu ng Bayanihan o pagtutulungan ng mga kapitbahay."
	},
	11: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "DAMULAG",
		"clue": "Isa itong malaking hayop na tumutulong sa pagsasaka.",
		"audio": "damulag.mp3",
		"meaning": "Kalabaw sa wikang Bikol.",
		"cultural_note": "Ang 'damulag' ang pambansang simbolo ng sipag at tiyaga ng mga magsasakang Bikolano."
	},
	12: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "BALUKAG",
		"clue": "Ito ang balahibo ng mga ibon o manok na nagbibigay ng proteksyon.",
		"audio": "balukag.mp3",
		"meaning": "Balahibo ng ibon o manok.",
		"cultural_note": "Ginagamit din ang salitang ito kapag sinasabing 'nagpapatayo ng balukag' (pangingilabot)."
	},
	13: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "MARIKAS",
		"clue": "Ito ay taong o bagay na kumikilos nang mabilis.",
		"audio": "marikas.mp3",
		"meaning": "Mabilis o matulin.",
		"cultural_note": "Inilalarawan ang isang taong maagap at mabilis gumawa ng mga gawaing-bahay."
	},
	14: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "MAKUSOG",
		"clue": "Ito ay taong may malakas na katawan o lakas.",
		"audio": "makusog.mp3",
		"meaning": "Malakas o matatag.",
		"cultural_note": "Isang katangian ng mga Bikolano na matatag sa anumang pagsubok o bagyo."
	},
	15: {
		"unit": "Yunit 3: Kultura at Tradisyon",
		"word": "MAGAYON",
		"clue": "Ito ay paglalarawan sa isang tao, bagay, o lugar na kaaya-aya sa paningin.",
		"audio": "magayon.mp3",
		"meaning": "Maganda sa wikang Bikol.",
		"cultural_note": "Hango sa alamat ni 'Daragang Magayon' kung saan nagmula ang Bulkang Mayon."
	},
	16: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "NAGSAKAT",
		"clue": "Ito ay pag-akyat sa puno, bundok, hagdan, o mataas na lugar.",
		"audio": "nagsakat.mp3",
		"meaning": "Umayat o umakyat.",
		"cultural_note": "Karaniwang ginagamit sa paglalarawan ng pag-akyat sa puno ng niyog."
	},
	17: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "BUTBOTKUWAW",
		"clue": "Isa itong ibon na gising sa gabi.",
		"audio": "butbotkuwaw.mp3",
		"meaning": "Kuwago (Owl).",
		"cultural_note": "Sa mga kwentong bayan, inuugnay ang kwago sa mga kwentong kababalaghan sa gabi."
	},
	18: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "HALABANG KAMOT",
		"clue": "Tumutukoy sa taong kumukuha ng gamit ng iba nang walang pahintulot.",
		"audio": "halabang_kamot.mp3",
		"meaning": "Idyoma na nangangahulugang magnanakaw.",
		"cultural_note": "Isang idyomang Bikol na nagtuturo ng pagiging tapat at pag-iwas sa pagkuha ng hindi pagmamay-ari."
	},
	19: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "MAHAMIS AN DILA",
		"clue": "Tumutukoy sa taong mahusay magsalita at madaling makapanghikayat ng iba.",
		"audio": "mahamis_an_dila.mp3",
		"meaning": "Idyoma na nangangahulugang mabulaklak magsalita o bolero.",
		"cultural_note": "Inilalarawan nito ang mga taong magaling makipag-usap at manghikayat."
	},
	20: {
		"unit": "Yunit 4: Kwentong Bayan at Idyoma",
		"word": "NAGSUSULO NIN KIRAY",
		"clue": "Tumutukoy sa taong nagpupuyat at nagsisikap upang mag-aral o matapos ang gawain.",
		"audio": "nagsusulo_nin_kiray.mp3",
		"meaning": "Idyoma na katumbas ng 'nagsusunog ng kilay' (nagsisikap mag-aral).",
		"cultural_note": "Simbolo ng pagsusumikap ng mga estudyanteng Bikolano para sa kanilang kinabukasan."
	}
}
