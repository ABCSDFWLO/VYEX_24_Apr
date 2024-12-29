extends Control

signal enter_game()

var token_manager : Node
var scene_manager : Node

@onready var search_http_request : HTTPRequest = $VBoxContainer/HBoxContainer/SearchButton/HTTPRequest
@onready var refresh_http_request : HTTPRequest = $VBoxContainer/HBoxContainer/RefreshButton/HTTPRequest
@onready var create_http_request : HTTPRequest = $CreatePanel/MarginContainer/VBoxContainer/CreateButton/HTTPRequest
@onready var search_lineedit : LineEdit = $VBoxContainer/HBoxContainer/SearchLineEdit
@onready var create_panel : PanelContainer = $CreatePanel
@onready var create_name_lineedit : LineEdit = $CreatePanel/MarginContainer/VBoxContainer/NameLineEdit
@onready var create_password_lineedit : LineEdit = $CreatePanel/MarginContainer/VBoxContainer/PasswordLineEdit
@onready var room_grid_container : GridContainer = $VBoxContainer/PanelContainer/ScrollContainer/GridContainer

var rooms : Array[Dictionary]

func _ready() -> void:
	token_manager=get_node("/root/Main/TokenManager")
	scene_manager=get_node("/root/Main/SceneManager")
	enter_game.connect(scene_manager._on_lobby_enter_game)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func render()->void:
	pass

func refresh()->void:
	var query : String = "?name="+search_lineedit.text
	var error = refresh_http_request.request("http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.GAMES_URL+query,[],HTTPClient.METHOD_GET)
	if error != OK:
		push_error("error occurred while http request", error)

func _on_refresh_button_pressed() -> void:
	refresh()

func _on_create_button_pressed() -> void:
	create_panel.modulate=Color(1,1,1,0)
	create_panel.visible=true
	var tween = get_tree().create_tween()
	tween.tween_property(create_panel,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_cancel_button_pressed() -> void:
	create_panel.modulate=Color(1,1,1,1)
	var tween = get_tree().create_tween()
	tween.tween_property(create_panel,"modulate",Color(1,1,1,0),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func()->void:
		create_panel.visible=false
		)

func _on_create_panel_create_button_pressed() -> void:
	var url = "http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.CREATE_GAME_URL
	var body = JSON.new().stringify({"name":create_name_lineedit.text,"password":create_password_lineedit.text})
	var header = token_manager.get_token_header()
	var error = create_http_request.request(url,header,HTTPClient.METHOD_POST,body)
	if error != OK:
		push_error("error occurred while http request", error)

func _on_create_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK and response_code != HTTPClient.RESPONSE_CREATED:
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg = "Unexpected error occurred. retry later."
		if data.has("detail"):
			var detail = data["detail"]
			if detail is Array and detail.size() > 0 and detail[0].has("msg"):
				msg = detail[0]["msg"]
			else:
				msg = detail
		push_error(msg)
	else:
		var response_tokens = JSON.parse_string(body.get_string_from_utf8())
		enter_game.emit()
