extends TextureButton

const hovered_color := Color(1,1,1,1)
const clicked_color := Color("F4CE14",1)

const disabled_color := Color(0,0,0,0.2)
const enabled_color := Color(1,1,1,0.6)

func _ready() -> void:
	self.modulate=enabled_color
func _on_mouse_entered() -> void:
	self.modulate=hovered_color
func _on_mouse_exited() -> void:
	if self.disabled:
		self.modulate=disabled_color
	else:
		self.modulate=enabled_color
func _on_button_down() -> void:
	self.modulate=clicked_color
func _on_button_up() -> void:
	self.modulate=hovered_color
func _on_camera_3d_top_view() -> void:
	self.modulate=disabled_color
	self.disabled=true
func _on_camera_3d_top_view_animation_ended() -> void:
	self.modulate=enabled_color
	self.disabled=false
func _on_pressed() -> void:
	_on_camera_3d_top_view()
