extends Control

@onready var logo_stroke :TextureRect = $LogoStroke
@onready var main_enter_button :Button = $LogoStroke/MainEnterButton
@onready var login_form : Control = $LoginForm
@onready var login_id_textedit : TextEdit = $LoginForm/panel/IdTextEdit
@onready var login_password_textedit : TextEdit = $LoginForm/panel/PasswordTextEdit

@onready var http_request : HTTPRequest = $HTTPRequest

const HOST := "localhost"
const PORT_WITH_COLON := ":8000"
const LOGIN_URL := "/login"

func _on_main_enter_button_pressed() -> void:
	main_enter_button.visible=false
	var tween = get_tree().create_tween()
	tween.tween_property(logo_stroke,"position",logo_stroke.position+Vector2.LEFT*250,0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(login_form,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_login_button_pressed() -> void:
	http_request.request("http://"+HOST+PORT_WITH_COLON+"/")
