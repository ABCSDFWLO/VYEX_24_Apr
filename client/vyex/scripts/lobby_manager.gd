extends Control

signal enter_game()

@onready var token_manager : Node = get_node("/root/Main/TokenManager")
@onready var scene_manager : Node = get_node("/root/Main/SceneManager")

@onready var search_http_request : HTTPRequest = $VBoxContainer/HBoxContainer/SearchButton/HTTPRequest
@onready var refresh_http_request : HTTPRequest = $VBoxContainer/HBoxContainer/RefreshButton/HTTPRequest
@onready var create_http_request : HTTPRequest = $CreatePanel/MarginContainer/VBoxContainer/HBoxContainer3/CreateButton/HTTPRequest
@onready var search_lineedit : LineEdit = $VBoxContainer/HBoxContainer/SearchLineEdit
@onready var create_panel : PanelContainer = $CreatePanel
@onready var create_name_lineedit : LineEdit = $CreatePanel/MarginContainer/VBoxContainer/NameLineEdit
@onready var create_password_lineedit : LineEdit = $CreatePanel/MarginContainer/VBoxContainer/PasswordLineEdit
@onready var create_host_first_buttongroup : ButtonGroup = $CreatePanel/MarginContainer/VBoxContainer/HBoxContainer/RandomCheckBox.button_group
@onready var room_grid_container : GridContainer = $VBoxContainer/PanelContainer/ScrollContainer/GridContainer
@onready var join_panel : PanelContainer = $JoinPanel
@onready var join_button : Button = $JoinPanel/MarginContainer/VBoxContainer/JoinButton
@onready var join_password_lineedit : LineEdit = $JoinPanel/MarginContainer/VBoxContainer/PasswordLineEdit
@onready var join_http_request : HTTPRequest = $JoinPanel/MarginContainer/VBoxContainer/JoinButton/HTTPRequest

var rooms : Array

func _ready() -> void:
	enter_game.connect(scene_manager._on_lobby_enter_game)

func render()->void:
	room_grid_container.clear()
	for game in rooms:
		var id : int = game["id"]
		var name : String = game["name"]
		var locked : bool = game["has_password"]
		var player1 : String = game["player1"]["name"] if not game["player1"] == null else ""
		var player2 : String = game["player2"]["name"] if not game["player2"] == null else ""
		room_grid_container.add_row(id,name,locked,player1,player2)

func refresh()->void:
	var query : String = "?name="+search_lineedit.text
	var error = refresh_http_request.request("http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.GAMES_URL+query,[],HTTPClient.METHOD_GET)
	if error != OK:
		push_error("error occurred while http request", error)

func _validate_game(game : Dictionary) -> bool:
	return game.has("id") and game.has("state") and game.has("name") and game.has("has_password") and game.has("player1") and game.has("player2")

func _http_response_preprocess(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, callback: Callable, error_callback: Callable) -> void:
	if response_code != HTTPClient.RESPONSE_OK and response_code != HTTPClient.RESPONSE_CREATED:
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg = "Unexpected error occurred. retry later."
		if data == null:
			msg = body.get_string_from_utf8()
		elif data.has("detail"):
			var detail = data["detail"]
			if detail is Array and detail.size() > 0 and detail[0].has("msg"):
				msg = detail[0]["msg"] # 422
			else:
				msg = detail # 400,401,403,...etc
		push_error("msg:"+msg)
		error_callback.callv([msg])
	else:
		var response = JSON.parse_string(body.get_string_from_utf8())
		callback.callv([response])

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
	var name = create_name_lineedit.text
	var password = create_password_lineedit.text
	var host_first = create_host_first_buttongroup.get_pressed_button().get_index()
	var body = JSON.new().stringify({"name":name,"password":password,"host_first":host_first})
	var header = token_manager.get_token_header()
	var error = create_http_request.request(url,header,HTTPClient.METHOD_POST,body)
	if error != OK:
		push_error("error occurred while http request", error)

func _on_create_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_http_response_preprocess(result, response_code, headers, body,
	func(response):
		enter_game.emit(),
	func(msg):pass
	)

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_http_response_preprocess(result, response_code, headers, body,
	func(response_games):
		for game in response_games:
			if not _validate_game(game):
				return
		rooms = response_games
		render(),
	func(msg):pass
	)

func _on_join_button_pressed(id : int, locked : bool):
	var url = "http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.ENTER_GAME_URL+"/"+str(id)
	var header = token_manager.get_token_header()
	if locked:
		join_panel.modulate=Color(1,1,1,0)
		join_panel.visible=true
		var tween = get_tree().create_tween()
		tween.tween_property(join_panel,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		join_button.pressed.connect(func():
			var body = "\""+join_password_lineedit.text+"\""
			join_http_request.request(url,header,HTTPClient.METHOD_POST,body)
			)
	else:
		join_http_request.request(url,header,HTTPClient.METHOD_POST)

func _on_join_panel_cancel_button_pressed() -> void:
	join_panel.modulate=Color(1,1,1,1)
	var tween = get_tree().create_tween()
	tween.tween_property(join_panel,"modulate",Color(1,1,1,0),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func()->void:
		join_panel.visible=false
		)

func _on_join_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_http_response_preprocess(result, response_code, headers, body,
	func(response):
		enter_game.emit(),
	func(msg):pass
	)
