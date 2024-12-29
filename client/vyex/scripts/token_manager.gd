extends Node

@onready var timer : Timer = $Timer
@onready var token_http_request : HTTPRequest = $TokenHTTPRequest

var tokens : Array[String] = ['1','2','3']

func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	var data = _parse_tokens()
	print(data)
	var error = token_http_request.request("http://"+Constants.HOST+Constants.PORT_WITH_COLON+Constants.TOKEN_URL,[],HTTPClient.METHOD_POST,data)
	if error != OK:
		push_error("error occurred while http request", error)
	timer.start()

func _on_token_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK and response_code != HTTPClient.RESPONSE_CREATED:
		var data = JSON.parse_string(body.get_string_from_utf8())
		var msg = "Unexpected error occurred. retry later."
		if data.has("detail"):
			var detail = data["detail"]
			if detail is Array and detail.size() > 0 and detail[0].has("msg"):
				msg = detail[0]["msg"]
			else:
				msg = detail
		push_error("msg: ", msg)
	else:
		var response_token = JSON.parse_string(body.get_string_from_utf8())
		for i in range(0,3):
			tokens[i]=response_token[i]

func _parse_tokens() -> String:
	var result = "["
	for token in tokens :
		result += "\""+ token+"\","
	result[-1] = "]"
	return result

func get_token_header() -> Array[String]:
	var result :Array[String]= []
	for i in range(3) :
		result.append("token"+str(i+1)+":"+tokens[i])
	return result

func _on_control_login(tokens: Array) -> void:
	for i in range(0,3):
		self.tokens[i]=tokens[i]
