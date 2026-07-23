extends Node2D

@onready var hint_label = $CanvasLayer/VBoxContainer/TagalogHintText
@onready var answer_row = $CanvasLayer/AnswerSlotsRow
@onready var scrambled_grid = $CanvasLayer/ScrambledLettersGrid

var correct_word: String = "BALUKAG"

# Ang mga Index na may NAKALAGAY NA AGAD na letra sa simula:
# Index 0='B', 2='L', 3='U', 5='A', 6='G' (0-based counting)
var prefilled_indices: Array = [0, 2, 3, 5, 6] 

# Ang kailangan na lang hanapin ay 'A' at 'K' + mga panggulo (distractors)
var remaining_letters: Array = ["A", "K", "E", "I", "O", "T", "D", "H", "S", "M", "N", "P", "R", "W"]

func _ready():
	setup_game()

func setup_game():
	# 1. I-setup ang Answer Slots sa taas (may pre-filled letters na)
	var answer_slots = answer_row.get_children()
	for i in range(answer_slots.size()):
		var slot = answer_slots[i]
		if i in prefilled_indices:
			slot.text = correct_word[i] # Kakarga 'yung B, L, U, A, G
			slot.is_locked = true       # HINDI na pwedeng galawin/i-drag
			# Optional: Pwede mong lagyan ng visually distinct disabled state dito
		else:
			slot.text = ""
			slot.is_locked = false

	# 2. I-shuffle ang pagpipiliang mga letra para sa baba
	remaining_letters.shuffle()
	
	# 3. Ilagay ang letters sa ScrambledLettersGrid buttons
	var letter_buttons = scrambled_grid.get_children()
	for i in range(letter_buttons.size()):
		if i < remaining_letters.size():
			letter_buttons[i].text = remaining_letters[i]
		else:
			letter_buttons[i].text = ""

# Ang tumatawag dito ay ang AnswerSlot.gd kapag may nai-drop na letter
func check_answer():
	var current_answer = ""
	var answer_slots = answer_row.get_children()
	
	for slot in answer_slots:
		current_answer += slot.text
		
	# Kapag napunan na ang lahat ng 7 slots
	if current_answer.length() == correct_word.length():
		if current_answer == correct_word:
			hint_label.text = "TAMA! Napakahusay!"
			print("Panalo!")
		else:
			hint_label.text = "Mali ang baybay. Subukan ulit!"
			print("Mali ang sagot.")
