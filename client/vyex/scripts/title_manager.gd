extends Control

signal login(tokens : Array)

@onready var logo_stroke :TextureRect = $LogoStroke
@onready var main_enter_button :Button = $LogoStroke/MainEnterButton
@onready var login_form : Control = $LoginForm
@onready var login_id_lineedit : LineEdit = $LoginForm/panel/IdLineEdit
@onready var login_password_lineedit : LineEdit = $LoginForm/panel/PasswordLineEdit
@onready var login_error_label : Label = $LoginForm/panel/LoginErrorLabel
@onready var register_form : Control = $RegisterForm
@onready var register_id_lineedit : LineEdit = $RegisterForm/panel/IdLineEdit
@onready var register_name_lineedit : LineEdit = $RegisterForm/panel/NameLineEdit
@onready var register_password_lineedit : LineEdit = $RegisterForm/panel/PasswordLineEdit
@onready var register_password_check_lineedit : LineEdit = $RegisterForm/panel/PasswordCheckLineEdit
@onready var register_error_label : Label = $RegisterForm/panel/RegisterErrorLabel
@onready var register_verify_form : Control = $RegisterVerifyForm
@onready var register_verify_email_label : Label = $RegisterVerifyForm/panel/EmailLabel
@onready var register_verify_error_label : Label = $RegisterVerifyForm/panel/VerifyErrorLabel
@onready var register_verify_codes : Array[LineEdit] = [
	$RegisterVerifyForm/panel/HBoxContainer/Code1,
	$RegisterVerifyForm/panel/HBoxContainer/Code2,
	$RegisterVerifyForm/panel/HBoxContainer/Code3,
	$RegisterVerifyForm/panel/HBoxContainer/Code4,
	$RegisterVerifyForm/panel/HBoxContainer/Code5,
	$RegisterVerifyForm/panel/HBoxContainer/Code6
	]

@onready var login_http_request : HTTPRequest = $LoginForm/LoginHTTPRequest
@onready var register_http_request : HTTPRequest = $RegisterForm/RegisterHTTPRequest
@onready var register_verify_http_request : HTTPRequest = $RegisterVerifyForm/RegisterVerifyHTTPRequest

var register_verify_url : String = ""
var register_verify_email : String = ""

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
		push_error("error occurred while http request", error)

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
		login_error_label.modulate=Color(0.5,0,0,1)
		login_error_label.text=msg
		login_error_label.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(login_error_label,"modulate",Color(0.5,0,0,0),2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		var response_tokens = JSON.parse_string(body.get_string_from_utf8())
		login.emit(response_tokens)

func _on_register_button_pressed() -> void:
	login_form.visible=false
	register_form.visible=true

func _on_register_back_button_pressed() -> void:
	register_form.visible=false
	login_form.visible=true

func _on_submit_button_pressed() -> void:
	var id = register_id_lineedit.text
	var password = register_password_lineedit.text
	var password_check = register_password_check_lineedit.text
	if (password == password_check):
		var body = JSON.new().stringify({"name":register_name_lineedit.text,"email":register_id_lineedit.text,"password":register_password_lineedit.text})
		var error = register_http_request.request("http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.REGISTER_URL,[],HTTPClient.METHOD_POST, body)
		if error != OK:
			push_error("error occurred while http request", error)
	else:
		register_error_label.modulate=Color(0.5,0,0,1)
		register_error_label.text="Password do not match."
		register_error_label.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(register_error_label,"modulate",Color(0.5,0,0,0),2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_register_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK and response_code != HTTPClient.RESPONSE_CREATED:
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg = "Unexpected error occurred. retry later."
		if data.has("detail"):
			var detail = data["detail"]
			if detail is Array and detail.size() > 0 and detail[0].has("msg"):
				msg = detail[0]["msg"]
			else:
				msg = detail
		register_error_label.modulate=Color(0.5,0,0,1)
		register_error_label.text=msg
		register_error_label.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(register_error_label,"modulate",Color(0.5,0,0,0),2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		var response_url = JSON.parse_string(body.get_string_from_utf8())
		self.register_verify_email = register_id_lineedit.text
		self.register_verify_url = "/"+response_url
		register_verify_email_label.text = register_verify_email
		register_form.visible = false
		register_verify_form.visible = true

func _on_verify_button_pressed() -> void:
	var codes : Array[String] = []
	for code_lineedit in register_verify_codes:
		if code_lineedit.text.is_empty():
			break
		codes.append(code_lineedit.text)
	if codes.size() != 6:
		register_verify_error_label.modulate=Color(0.5,0,0,1)
		register_verify_error_label.text="Verification code is required"
		register_verify_error_label.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(register_error_label,"modulate",Color(0.5,0,0,0),2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		var code : String = ""
		for character in codes:
			code += character
		var body = "\"" + code + "\""
		var error = register_verify_http_request.request("http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.REGISTER_VERIFY_URL+self.register_verify_url,[],HTTPClient.METHOD_POST, body)
		if error != OK:
			push_error("error occurred while http request", error)

func _on_register_verify_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK and response_code != HTTPClient.RESPONSE_CREATED:
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg = "Unexpected error occurred. retry later."
		if data.has("detail"):
			var detail = data["detail"]
			if detail is Array and detail.size() > 0 and detail[0].has("msg"):
				msg = detail[0]["msg"]
			else:
				msg = detail
		register_verify_error_label.modulate=Color(0.5,0,0,1)
		register_verify_error_label.text=msg
		register_verify_error_label.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(register_verify_error_label,"modulate",Color(0.5,0,0,0),2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		var response = JSON.parse_string(body.get_string_from_utf8())
		print(response)
		register_verify_form.visible=false
