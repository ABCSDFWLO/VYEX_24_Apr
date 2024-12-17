extends Camera3D

signal cursor_viewport_pos_changed(pos : Vector2)

const MOVE_ACC = 1.0
const ROT_ACC = 0.2

const MOVE_SPD_MAX = 10.0
const ROT_SPD_MAX = 2.0

const MOVE_SPD_EPS = 1.1
const ROT_SPD_EPS = 0.21

const ROT_DIR_MAX = 0.99

const MOUSE_MOVE_SPD = 0.3
const MOUSE_WHEEL_UNIT = 30

var move_spd := Vector3(0,0,0)
var rot_spd := Vector2(0,0)

var cursor_pivot : Node3D
var cursor_viewport_pos : Vector2

enum MouseDragMode { IDLE, MOVE, ROTATE, ZOOM }
var perspective_first : bool = false
var mouse_drag_mode : int = MouseDragMode.IDLE
var mouse_move_sensitivity : float = 0.05
var mouse_rotate_sensitivity : float = 0.005
var mouse_zoom_sensitivity : float = 0.05
var mouse_vector_sum := Vector3(0,0,0)

func _ready() -> void:
	cursor_pivot = get_parent()
	perspective_first=false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_with_drag"):
		mouse_drag_mode = MouseDragMode.MOVE
	elif event.is_action_pressed("rotate_with_drag"):
		mouse_drag_mode = MouseDragMode.ROTATE
	elif event.is_action_pressed("zoom_with_drag"):
		mouse_drag_mode = MouseDragMode.ZOOM
	
	if event.is_action_released("move_with_drag") \
	or event.is_action_released("rotate_with_drag") \
	or event.is_action_released("zoom_with_drag") :
		mouse_drag_mode=MouseDragMode.IDLE
	
	if event is InputEventMouseMotion:
		var motion:InputEventMouseMotion = event
		var sum_x = mouse_vector_sum.x
		var sum_y = mouse_vector_sum.y
		match mouse_drag_mode:
			MouseDragMode.IDLE:
				pass
			MouseDragMode.MOVE:
				sum_x -= mouse_move_sensitivity * motion.relative.x
				sum_y += mouse_move_sensitivity * motion.relative.y
			MouseDragMode.ROTATE:
				sum_x -= mouse_rotate_sensitivity * motion.relative.x
				sum_y -= mouse_rotate_sensitivity * motion.relative.y
			MouseDragMode.ZOOM:
				sum_y += mouse_zoom_sensitivity * motion.relative.y
		mouse_vector_sum = Vector3(sum_x,sum_y,0)
		
	if event.is_action_pressed("change_perspective"):
		perspective_first=not perspective_first
		
	if event.is_action_released("wheel_up"):
		self.translate(Vector3(0,0,mouse_zoom_sensitivity*MOUSE_WHEEL_UNIT))
	elif event.is_action_released("wheel_down"):
		self.translate(Vector3(0,0,-mouse_zoom_sensitivity*MOUSE_WHEEL_UNIT))

func _process(delta: float) -> void:
	var mouse_vector :Vector3 = mouse_vector_sum*MOUSE_MOVE_SPD
	if perspective_first :
		move_first(delta)
		mouse_first(mouse_vector)
	else:
		move_third(delta)
		mouse_third(mouse_vector)
	render_cursor()

func move_first(delta : float) -> void:
	if Input.is_action_pressed("move_left"):
		if move_spd.x< -MOVE_SPD_MAX:
			move_spd.x = -MOVE_SPD_MAX
		else:
			move_spd.x -= MOVE_ACC
	elif Input.is_action_pressed("move_right"):
		if move_spd.x > MOVE_SPD_MAX:
			move_spd.x = MOVE_SPD_MAX
		else:
			move_spd.x += MOVE_ACC
	else:
		if move_spd.x < MOVE_SPD_EPS and move_spd.x > -MOVE_SPD_EPS:
			move_spd.x = 0
		elif move_spd.x > 0:
			move_spd.x -= MOVE_ACC
		elif move_spd.x < 0:
			move_spd.x += MOVE_ACC
	
	if Input.is_action_pressed("move_front"):
		if move_spd.z < -MOVE_SPD_MAX:
			move_spd.z = -MOVE_SPD_MAX
		else:
			move_spd.z -= MOVE_ACC
	elif Input.is_action_pressed("move_back"):
		if move_spd.z > MOVE_SPD_MAX:
			move_spd.z = MOVE_SPD_MAX
		else:
			move_spd.z += MOVE_ACC
	else:
		if move_spd.z < MOVE_SPD_EPS and move_spd.z > -MOVE_SPD_EPS:
			move_spd.z = 0
		elif move_spd.z > 0:
			move_spd.z -= MOVE_ACC
		elif move_spd.z < 0:
			move_spd.z += MOVE_ACC

	if Input.is_action_pressed("move_up"):
		if move_spd.y > MOVE_SPD_MAX:
			move_spd.y = MOVE_SPD_MAX
		else:
			move_spd.y += MOVE_ACC
	elif Input.is_action_pressed("move_down"):
		if move_spd.y < -MOVE_SPD_MAX:
			move_spd.y = -MOVE_SPD_MAX
		else:
			move_spd.y -= MOVE_ACC
	else:
		if move_spd.y < MOVE_SPD_EPS and move_spd.y > -MOVE_SPD_EPS:
			move_spd.y = 0
		elif move_spd.y > 0:
			move_spd.y -= MOVE_ACC
		elif move_spd.y < 0:
			move_spd.y += MOVE_ACC
	
	if Input.is_action_pressed("rotate_x_clock"):
		if rot_spd.x < -ROT_SPD_MAX:
			rot_spd.x = -ROT_SPD_MAX
		else:
			rot_spd.x -= ROT_ACC
	elif Input.is_action_pressed("rotate_x_counterclock"):
		if rot_spd.x > ROT_SPD_MAX:
			rot_spd.x = ROT_SPD_MAX
		else:
			rot_spd.x += ROT_ACC
	else:
		if rot_spd.x < ROT_SPD_EPS and rot_spd.x > -ROT_SPD_EPS:
			rot_spd.x = 0
		elif rot_spd.x > 0:
			rot_spd.x -= ROT_ACC
		elif rot_spd.x < 0:
			rot_spd.x += ROT_ACC
	
	if Input.is_action_pressed("rotate_y_clock"):
		if rot_spd.y > ROT_SPD_MAX:
			rot_spd.y = ROT_SPD_MAX
		else:
			rot_spd.y += ROT_ACC
	elif Input.is_action_pressed("rotate_y_counterclock"):
		if rot_spd.y < -ROT_SPD_MAX:
			rot_spd.y = -ROT_SPD_MAX
		else:
			rot_spd.y -= ROT_ACC
	else:
		if rot_spd.y < ROT_SPD_EPS and rot_spd.y > -ROT_SPD_EPS:
			rot_spd.y = 0
		elif rot_spd.y > 0:
			rot_spd.y -= ROT_ACC
		elif rot_spd.y < 0:
			rot_spd.y += ROT_ACC

	var direction = self.transform.basis.z.normalized()
	if direction.y >= ROT_DIR_MAX and rot_spd.y < 0:
		rot_spd.y = 0
	elif direction.y <= -ROT_DIR_MAX and rot_spd.y > 0:
		rot_spd.y = 0
		
	self.rotate(Vector3.UP, rot_spd.x * delta)
	self.rotate(self.transform.basis.x.normalized(), rot_spd.y * delta)
	self.translate(Vector3.RIGHT * move_spd.x * delta)
	self.translate(Vector3.UP * move_spd.y * delta)
	self.translate(Vector3.BACK * move_spd.z * delta)	
func move_third(delta : float):
	if Input.is_action_pressed("move_left"):
		if move_spd.x< -MOVE_SPD_MAX:
			move_spd.x = -MOVE_SPD_MAX
		else:
			move_spd.x -= MOVE_ACC
	elif Input.is_action_pressed("move_right"):
		if move_spd.x > MOVE_SPD_MAX:
			move_spd.x = MOVE_SPD_MAX
		else:
			move_spd.x += MOVE_ACC
	else:
		if move_spd.x < MOVE_SPD_EPS and move_spd.x > -MOVE_SPD_EPS:
			move_spd.x = 0
		elif move_spd.x > 0:
			move_spd.x -= MOVE_ACC
		elif move_spd.x < 0:
			move_spd.x += MOVE_ACC
	
	if Input.is_action_pressed("move_front"):
		if move_spd.z < -MOVE_SPD_MAX:
			move_spd.z = -MOVE_SPD_MAX
		else:
			move_spd.z -= MOVE_ACC
	elif Input.is_action_pressed("move_back"):
		if move_spd.z > MOVE_SPD_MAX:
			move_spd.z = MOVE_SPD_MAX
		else:
			move_spd.z += MOVE_ACC
	else:
		if move_spd.z < MOVE_SPD_EPS and move_spd.z > -MOVE_SPD_EPS:
			move_spd.z = 0
		elif move_spd.z > 0:
			move_spd.z -= MOVE_ACC
		elif move_spd.z < 0:
			move_spd.z += MOVE_ACC

	if Input.is_action_pressed("move_up"):
		if move_spd.y > MOVE_SPD_MAX:
			move_spd.y = MOVE_SPD_MAX
		else:
			move_spd.y += MOVE_ACC
	elif Input.is_action_pressed("move_down"):
		if move_spd.y < -MOVE_SPD_MAX:
			move_spd.y = -MOVE_SPD_MAX
		else:
			move_spd.y -= MOVE_ACC
	else:
		if move_spd.y < MOVE_SPD_EPS and move_spd.y > -MOVE_SPD_EPS:
			move_spd.y = 0
		elif move_spd.y > 0:
			move_spd.y -= MOVE_ACC
		elif move_spd.y < 0:
			move_spd.y += MOVE_ACC
	
	if Input.is_action_pressed("rotate_x_clock"):
		if rot_spd.x < -ROT_SPD_MAX:
			rot_spd.x = -ROT_SPD_MAX
		else:
			rot_spd.x -= ROT_ACC
	elif Input.is_action_pressed("rotate_x_counterclock"):
		if rot_spd.x > ROT_SPD_MAX:
			rot_spd.x = ROT_SPD_MAX
		else:
			rot_spd.x += ROT_ACC
	else:
		if rot_spd.x < ROT_SPD_EPS and rot_spd.x > -ROT_SPD_EPS:
			rot_spd.x = 0
		elif rot_spd.x > 0:
			rot_spd.x -= ROT_ACC
		elif rot_spd.x < 0:
			rot_spd.x += ROT_ACC
	
	if Input.is_action_pressed("rotate_y_clock"):
		if rot_spd.y > ROT_SPD_MAX:
			rot_spd.y = ROT_SPD_MAX
		else:
			rot_spd.y += ROT_ACC
	elif Input.is_action_pressed("rotate_y_counterclock"):
		if rot_spd.y < -ROT_SPD_MAX:
			rot_spd.y = -ROT_SPD_MAX
		else:
			rot_spd.y -= ROT_ACC
	else:
		if rot_spd.y < ROT_SPD_EPS and rot_spd.y > -ROT_SPD_EPS:
			rot_spd.y = 0
		elif rot_spd.y > 0:
			rot_spd.y -= ROT_ACC
		elif rot_spd.y < 0:
			rot_spd.y += ROT_ACC

	var direction = self.transform.basis.z.normalized()
	if direction.y >= ROT_DIR_MAX and rot_spd.y < 0:
		rot_spd.y = 0
	elif direction.y <= -ROT_DIR_MAX and rot_spd.y > 0:
		rot_spd.y = 0
		
	self.rotate(Vector3.UP, rot_spd.x * delta)
	self.rotate(self.transform.basis.x.normalized(), rot_spd.y * delta)
	self.translate(Vector3.RIGHT * move_spd.x * delta)
	self.translate(Vector3.UP * move_spd.y * delta)
	self.translate(Vector3.BACK * move_spd.z * delta)	

func mouse_first(mouse_vector : Vector3):
	if not mouse_vector.is_equal_approx(Vector3(0,0,0)):
		mouse_vector_sum -= mouse_vector
		match mouse_drag_mode:
			MouseDragMode.IDLE:
				pass
			MouseDragMode.MOVE:
				move_spd=Vector3(0,0,0)
				self.translate(mouse_vector)
			MouseDragMode.ROTATE:
				var direction = self.transform.basis.z.normalized()
				if direction.y >= ROT_DIR_MAX and mouse_vector.y < 0:
					mouse_vector.y = 0
				elif direction.y <= -ROT_DIR_MAX and mouse_vector.y > 0:
					mouse_vector.y = 0
				self.rotate(Vector3.UP, mouse_vector.x)
				self.rotate(self.transform.basis.x.normalized(),mouse_vector.y)
			MouseDragMode.ZOOM:
				self.translate(Vector3(0,0,mouse_vector.y))
func mouse_third(mouse_vector : Vector3):
	if not mouse_vector.is_equal_approx(Vector3(0,0,0)):
			mouse_vector_sum -= mouse_vector
			match mouse_drag_mode:
				MouseDragMode.IDLE:
					pass
				MouseDragMode.MOVE:
					move_spd=Vector3(0,0,0)
					cursor_pivot.translate(self.global_basis*mouse_vector)
				MouseDragMode.ROTATE:
					move_spd=Vector3(0,0,0)
					var direction = self.transform.basis.z.normalized()
					var distance = self.position.length()
					if direction.y >= ROT_DIR_MAX and mouse_vector.y < 0:
						mouse_vector.y = 0
					elif direction.y <= -ROT_DIR_MAX and mouse_vector.y > 0:
						mouse_vector.y = 0
					self.rotate(Vector3.UP, mouse_vector.x)
					self.rotate(self.transform.basis.x.normalized(),mouse_vector.y)
					var rot = self.global_rotation
					var pos = Vector3(sin(rot.y)*cos(rot.x)*distance,sin(-rot.x)*distance,cos(rot.y)*cos(rot.x)*distance)
					self.position = pos
				MouseDragMode.ZOOM:
					self.translate(Vector3(0,0,mouse_vector.y))
					
func render_cursor():
	var pos :Vector2 = unproject_position(cursor_pivot.global_position)
	if pos.is_equal_approx(cursor_viewport_pos):
		pass
	else:
		emit_signal("cursor_viewport_pos_changed", pos)
		cursor_viewport_pos = pos
