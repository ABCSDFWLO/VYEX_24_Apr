extends Sprite3D

signal cursor_highlight()

var camera : Node3D
var camera_direction : Vector3
var last_position : Vector3

var highlighted : bool

const SCALE_RATIO : float = 0.1

func _ready() -> void:
	camera = get_node("../Camera3D")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cursor_highlight"):
		highlighted=true
		self.last_position = self.position
		emit_signal("cursor_highlight")
	elif event.is_action_released("cursor_highlight"):
		highlighted=false
		self.position = self.last_position

func _process(_delta: float) -> void:
	highlight()
	look_camera()

func look_camera()->void:
	self.camera_direction = camera.global_transform.origin-self.global_transform.origin
	look_at(camera_direction,camera.global_transform.basis.y)
	
	var scale = self.camera_direction.length() * SCALE_RATIO
	self.scale = Vector3(scale,scale,scale)

func highlight()->void:
	if highlighted:
		var delta_scale : float = 1/camera_direction.length()*0.1
		var delta_dir : Vector3 = camera_direction*delta_scale
		var camera_nearest_offset : Vector3 = camera.position - delta_dir
		self.position = camera_nearest_offset
		self.modulate = Color(1, 1, 1, 0.6)
	else:
		self.modulate = Color(1, 1, 1, 0.4)
