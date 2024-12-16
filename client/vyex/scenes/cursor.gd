extends Control

const IDLE_COLOR = Color(1,1,1,0.5)
const HIGHLIGHTED_COLOR = Color(1,0,0,1)

func _ready() -> void:
	self.modulate = IDLE_COLOR

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cursor_highlight"):
		self.modulate = HIGHLIGHTED_COLOR
	elif event.is_action_released("cursor_highlight"):
		self.modulate = IDLE_COLOR

func _on_camera_3d_cursor_viewport_pos_changed(pos: Vector2) -> void:
	self.position = pos
