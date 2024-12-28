extends Control

@onready var codes: Array[LineEdit] = [
	$HBoxContainer/Code1,
	$HBoxContainer/Code2,
	$HBoxContainer/Code3,
	$HBoxContainer/Code4,
	$HBoxContainer/Code5,
	$HBoxContainer/Code6
]
@onready var verify_button: Button = $VerifyButton

func _ready() -> void:
	for i in codes.size():
		codes[i].text_changed.connect(func(new_text: String):
			_on_text_changed(new_text, i)
		)
		codes[i].text_submitted.connect(_on_text_submitted)

func _on_text_changed(new_text: String, index: int) -> void:
	if new_text.length() > 0 and index < codes.size() - 1:
		codes[index + 1].grab_focus()
		codes[index + 1].text = ""

func _on_text_submitted(submitted_text: String) -> void:
	verify_button.emit_signal("pressed")
