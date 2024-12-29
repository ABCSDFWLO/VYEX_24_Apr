extends Control

const IDLE_COLOR = Color(1,1,1,0.5)
const HIGHLIGHTED_COLOR = Color(1,0,0,1)

@onready var cursor : Array[Control] = [
	$CursorUpLeft,
	$CursorUp,
	$CursorUpRight,
	$CursorLeft,
	$CursorIn,
	$CursorRight,
	$CursorDownLeft,
	$CursorDown,
	$CursorDownRight
	]

func _ready() -> void:
	self.modulate = IDLE_COLOR

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cursor_highlight"):
		self.modulate = HIGHLIGHTED_COLOR
	elif event.is_action_released("cursor_highlight"):
		self.modulate = IDLE_COLOR

func _on_camera_3d_cursor_viewport_pos_changed(pos: Vector2) -> void:
	var top := 0
	var left := 0
	var right := get_viewport().get_visible_rect().size.x
	var bottom := get_viewport().get_visible_rect().size.y
	
	var index := 4
	
	if pos.x<left:
		index-=1
	elif pos.x>right:
		index+=1
	
	if pos.y<top:
		index-=3
	elif pos.y>bottom:
		index+=3
		
	for i in range(0,9):
		if i==index:
			cursor[i].visible=true
		else:
			cursor[i].visible=false
	
	match index:
		0,2,6,8:
			pass
		3,5:
			cursor[index].position.y=pos.y
		1,7:
			cursor[index].position.x=pos.x
		4:
			cursor[index].position=pos
