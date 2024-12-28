extends Control

@onready var logo_stroke :TextureRect = $LogoStroke
@onready var main_enter_button :Button = $LogoStroke/MainEnterButton
@onready var login_form : Control = $LoginForm
@onready var login_id_lineedit : LineEdit = $LoginForm/panel/IdLineEdit
@onready var login_password_lineedit : LineEdit = $LoginForm/panel/PasswordLineEdit
@onready var login_error_label : Label = $LoginForm/panel/LoginErrorLabel

@onready var login_http_request : HTTPRequest = $LoginForm/LoginHTTPRequest

signal login(tokens : Array)

func _on_main_enter_button_pressed() -> void:
	main_enter_button.visible=false
	login_form.visible=true
	var tween = get_tree().create_tween()
	tween.tween_property(logo_stroke,"position",logo_stroke.position+Vector2.LEFT*250,0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(login_form,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_login_button_pressed() -> void:
	var body = JSON.new().stringify({"email":login_id_lineedit.text,"password":login_password_lineedit.text})
	var error = login_http_request.request("http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.LOGIN_URL,[],HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("error occurred")

func _on_login_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK and response_code != HTTPClient.RESPONSE_CREATED:
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg = "Unexpected error occurred. retry later."
		if data.has("detail"):
			var detail = data["detail"]
			if detail is Array and detail.size() > 0 and detail[0].has("msg"):
				msg = detail[0]["msg"]
			else:
				msg = detail
		print("msg: ", msg)
		login_error_label.modulate=Color(0.5,0,0,1)
		login_error_label.text=msg
		login_error_label.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(login_error_label,"modulate",Color(0.5,0,0,0),2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		var response_tokens = JSON.parse_string(body.get_string_from_utf8())
		print(typeof(response_tokens),typeof(response_tokens[0]),response_tokens)
		print(login.get_connections())
		login.emit(response_tokens)
