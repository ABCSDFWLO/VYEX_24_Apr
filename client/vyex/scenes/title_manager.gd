extends Control

@onready var logo_stroke := $LogoStroke
@onready var main_enter_button := $LogoStroke/MainEnterButton
@onready var login_form := $LoginForm

func _on_main_enter_button_pressed() -> void:
	main_enter_button.visible=false
	var tween = get_tree().create_tween()
	tween.tween_property(logo_stroke,"position",logo_stroke.position+Vector2.LEFT*250,0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(login_form,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
