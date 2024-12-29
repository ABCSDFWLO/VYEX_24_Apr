extends Camera3D

signal cursor_viewport_pos_changed(pos : Vector2)
signal perspective_changed(is_first : bool)
signal top_view()
signal top_view_animation_ended()


var move_spd := Vector3(0,0,0)
var rot_spd := Vector2(0,0)

@onready var cursor_pivot : Node3D = get_parent()
var cursor_viewport_pos : Vector2

enum MouseDragMode { IDLE, MOVE, ROTATE, ZOOM }
var perspective_first := false
var mouse_drag_mode := MouseDragMode.IDLE
var mouse_move_sensitivity := 0.05
var mouse_rotate_sensitivity := 0.005
var mouse_zoom_sensitivity := 0.05
var mouse_vector_sum := Vector3(0,0,0)

var top_view_animation_progress := 0.0


func _ready() -> void:
	perspective_first=false
	top_view_animation_progress=Constants.TOP_VIEW_ANIMATION_DURATION

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
		_on_camera_lock_on_cursor_icon_button_pressed()
		perspective_changed.emit(perspective_first)
	if event.is_action_pressed("top_view"):
		_on_top_view_icon_button_pressed()
		top_view.emit()
	#if event.is_action_pressed("orthogonal_view"):
		#if self.projection==Camera3D.PROJECTION_ORTHOGONAL:
			#self.projection=Camera3D.PROJECTION_PERSPECTIVE
		#else:
			#self.projection=Camera3D.PROJECTION_ORTHOGONAL
			#self.size=self.position.length()
		
	if event.is_action_released("wheel_up"):
		#if self.projection==Camera3D.PROJECTION_ORTHOGONAL:
			#self.size-=0.5
		#else:
		self.translate(Vector3(0,0,-mouse_zoom_sensitivity*Constants.MOUSE_WHEEL_UNIT))
	elif event.is_action_released("wheel_down"):
		#if self.projection==Camera3D.PROJECTION_ORTHOGONAL:
			#self.size+=0.5
		#else:
		self.translate(Vector3(0,0,+mouse_zoom_sensitivity*Constants.MOUSE_WHEEL_UNIT))

func _process(delta: float) -> void:
	var mouse_vector :Vector3 = mouse_vector_sum*Constants.MOUSE_MOVE_SPD
	if top_view_animation_progress>0:
		top_view_animation(delta)
	elif perspective_first :
		move_first(delta)
		mouse_first(mouse_vector)
	else:
		move_third(delta)
		mouse_third(mouse_vector)
	render_cursor()

func move_first(delta : float) -> void:
	if Input.is_action_pressed("move_left"):
		if move_spd.x< -Constants.MOVE_SPD_MAX:
			move_spd.x = -Constants.MOVE_SPD_MAX
		else:
			move_spd.x -= Constants.MOVE_ACC
	elif Input.is_action_pressed("move_right"):
		if move_spd.x > Constants.MOVE_SPD_MAX:
			move_spd.x = Constants.MOVE_SPD_MAX
		else:
			move_spd.x += Constants.MOVE_ACC
	else:
		if move_spd.x < Constants.MOVE_SPD_EPS and move_spd.x > -Constants.MOVE_SPD_EPS:
			move_spd.x = 0
		elif move_spd.x > 0:
			move_spd.x -= Constants.MOVE_ACC
		elif move_spd.x < 0:
			move_spd.x += Constants.MOVE_ACC
	
	if Input.is_action_pressed("move_front"):
		if move_spd.z < -Constants.MOVE_SPD_MAX:
			move_spd.z = -Constants.MOVE_SPD_MAX
		else:
			move_spd.z -= Constants.MOVE_ACC
	elif Input.is_action_pressed("move_back"):
		if move_spd.z > Constants.MOVE_SPD_MAX:
			move_spd.z = Constants.MOVE_SPD_MAX
		else:
			move_spd.z += Constants.MOVE_ACC
	else:
		if move_spd.z < Constants.MOVE_SPD_EPS and move_spd.z > -Constants.MOVE_SPD_EPS:
			move_spd.z = 0
		elif move_spd.z > 0:
			move_spd.z -= Constants.MOVE_ACC
		elif move_spd.z < 0:
			move_spd.z += Constants.MOVE_ACC

	if Input.is_action_pressed("move_up"):
		if move_spd.y > Constants.MOVE_SPD_MAX:
			move_spd.y = Constants.MOVE_SPD_MAX
		else:
			move_spd.y += Constants.MOVE_ACC
	elif Input.is_action_pressed("move_down"):
		if move_spd.y < -Constants.MOVE_SPD_MAX:
			move_spd.y = -Constants.MOVE_SPD_MAX
		else:
			move_spd.y -= Constants.MOVE_ACC
	else:
		if move_spd.y < Constants.MOVE_SPD_EPS and move_spd.y > -Constants.MOVE_SPD_EPS:
			move_spd.y = 0
		elif move_spd.y > 0:
			move_spd.y -= Constants.MOVE_ACC
		elif move_spd.y < 0:
			move_spd.y += Constants.MOVE_ACC
	
	if Input.is_action_pressed("rotate_x_clock"):
		if rot_spd.x < -Constants.ROT_SPD_MAX:
			rot_spd.x = -Constants.ROT_SPD_MAX
		else:
			rot_spd.x -= Constants.ROT_ACC
	elif Input.is_action_pressed("rotate_x_counterclock"):
		if rot_spd.x > Constants.ROT_SPD_MAX:
			rot_spd.x = Constants.ROT_SPD_MAX
		else:
			rot_spd.x += Constants.ROT_ACC
	else:
		if rot_spd.x < Constants.ROT_SPD_EPS and rot_spd.x > -Constants.ROT_SPD_EPS:
			rot_spd.x = 0
		elif rot_spd.x > 0:
			rot_spd.x -= Constants.ROT_ACC
		elif rot_spd.x < 0:
			rot_spd.x += Constants.ROT_ACC
	
	if Input.is_action_pressed("rotate_y_clock"):
		if rot_spd.y > Constants.ROT_SPD_MAX:
			rot_spd.y = Constants.ROT_SPD_MAX
		else:
			rot_spd.y += Constants.ROT_ACC
	elif Input.is_action_pressed("rotate_y_counterclock"):
		if rot_spd.y < -Constants.ROT_SPD_MAX:
			rot_spd.y = -Constants.ROT_SPD_MAX
		else:
			rot_spd.y -= Constants.ROT_ACC
	else:
		if rot_spd.y < Constants.ROT_SPD_EPS and rot_spd.y > -Constants.ROT_SPD_EPS:
			rot_spd.y = 0
		elif rot_spd.y > 0:
			rot_spd.y -= Constants.ROT_ACC
		elif rot_spd.y < 0:
			rot_spd.y += Constants.ROT_ACC

	var direction = self.transform.basis.z.normalized()
	if direction.y >= Constants.ROT_DIR_MAX and rot_spd.y < 0:
		rot_spd.y = 0
	elif direction.y <= -Constants.ROT_DIR_MAX and rot_spd.y > 0:
		rot_spd.y = 0
		
	self.rotate(Vector3.UP, rot_spd.x * delta)
	self.rotate(self.transform.basis.x.normalized(), rot_spd.y * delta)
	self.global_translate(Vector3(direction.z,0,-direction.x).normalized() * move_spd.x * delta)
	self.global_translate(Vector3.UP * move_spd.y * delta)
	self.global_translate(Vector3(direction.x,0,direction.z).normalized() * move_spd.z * delta)
func move_third(delta : float) -> void:
	if Input.is_action_pressed("move_left"):
		if move_spd.x< -Constants.MOVE_SPD_MAX:
			move_spd.x = -Constants.MOVE_SPD_MAX
		else:
			move_spd.x -= Constants.MOVE_ACC
	elif Input.is_action_pressed("move_right"):
		if move_spd.x > Constants.MOVE_SPD_MAX:
			move_spd.x = Constants.MOVE_SPD_MAX
		else:
			move_spd.x += Constants.MOVE_ACC
	else:
		if move_spd.x < Constants.MOVE_SPD_EPS and move_spd.x > -Constants.MOVE_SPD_EPS:
			move_spd.x = 0
		elif move_spd.x > 0:
			move_spd.x -= Constants.MOVE_ACC
		elif move_spd.x < 0:
			move_spd.x += Constants.MOVE_ACC
	
	if Input.is_action_pressed("move_front"):
		if move_spd.z < -Constants.MOVE_SPD_MAX:
			move_spd.z = -Constants.MOVE_SPD_MAX
		else:
			move_spd.z -= Constants.MOVE_ACC
	elif Input.is_action_pressed("move_back"):
		if move_spd.z > Constants.MOVE_SPD_MAX:
			move_spd.z = Constants.MOVE_SPD_MAX
		else:
			move_spd.z += Constants.MOVE_ACC
	else:
		if move_spd.z < Constants.MOVE_SPD_EPS and move_spd.z > -Constants.MOVE_SPD_EPS:
			move_spd.z = 0
		elif move_spd.z > 0:
			move_spd.z -= Constants.MOVE_ACC
		elif move_spd.z < 0:
			move_spd.z += Constants.MOVE_ACC

	if Input.is_action_pressed("move_up"):
		if move_spd.y > Constants.MOVE_SPD_MAX:
			move_spd.y = Constants.MOVE_SPD_MAX
		else:
			move_spd.y += Constants.MOVE_ACC
	elif Input.is_action_pressed("move_down"):
		if move_spd.y < -Constants.MOVE_SPD_MAX:
			move_spd.y = -Constants.MOVE_SPD_MAX
		else:
			move_spd.y -= Constants.MOVE_ACC
	else:
		if move_spd.y < Constants.MOVE_SPD_EPS and move_spd.y > -Constants.MOVE_SPD_EPS:
			move_spd.y = 0
		elif move_spd.y > 0:
			move_spd.y -= Constants.MOVE_ACC
		elif move_spd.y < 0:
			move_spd.y += Constants.MOVE_ACC
	
	if Input.is_action_pressed("rotate_x_clock"):
		if rot_spd.x < -Constants.ROT_SPD_MAX:
			rot_spd.x = -Constants.ROT_SPD_MAX
		else:
			rot_spd.x -= Constants.ROT_ACC
	elif Input.is_action_pressed("rotate_x_counterclock"):
		if rot_spd.x > Constants.ROT_SPD_MAX:
			rot_spd.x = Constants.ROT_SPD_MAX
		else:
			rot_spd.x += Constants.ROT_ACC
	else:
		if rot_spd.x < Constants.ROT_SPD_EPS and rot_spd.x > -Constants.ROT_SPD_EPS:
			rot_spd.x = 0
		elif rot_spd.x > 0:
			rot_spd.x -= Constants.ROT_ACC
		elif rot_spd.x < 0:
			rot_spd.x += Constants.ROT_ACC
	
	if Input.is_action_pressed("rotate_y_clock"):
		if rot_spd.y > Constants.ROT_SPD_MAX:
			rot_spd.y = Constants.ROT_SPD_MAX
		else:
			rot_spd.y += Constants.ROT_ACC
	elif Input.is_action_pressed("rotate_y_counterclock"):
		if rot_spd.y < -Constants.ROT_SPD_MAX:
			rot_spd.y = -Constants.ROT_SPD_MAX
		else:
			rot_spd.y -= Constants.ROT_ACC
	else:
		if rot_spd.y < Constants.ROT_SPD_EPS and rot_spd.y > -Constants.ROT_SPD_EPS:
			rot_spd.y = 0
		elif rot_spd.y > 0:
			rot_spd.y -= Constants.ROT_ACC
		elif rot_spd.y < 0:
			rot_spd.y += Constants.ROT_ACC

	var direction = self.transform.basis.z.normalized()
	var distance = self.position.length()
	if direction.y >= Constants.ROT_DIR_MAX and rot_spd.y < 0:
		rot_spd.y = 0
	elif direction.y <= -Constants.ROT_DIR_MAX and rot_spd.y > 0:
		rot_spd.y = 0
		
	cursor_pivot.translate(Vector3(direction.z,0,-direction.x).normalized() * move_spd.x * delta)
	cursor_pivot.translate(Vector3.UP * move_spd.y * delta)
	cursor_pivot.translate(Vector3(direction.x,0,direction.z).normalized() * move_spd.z * delta)
	self.rotate(Vector3.UP, -rot_spd.x * delta)
	self.rotate(self.transform.basis.x.normalized(), rot_spd.y * delta)
	var rot = self.global_rotation
	var pos = Vector3(sin(rot.y)*cos(rot.x)*distance,sin(-rot.x)*distance,cos(rot.y)*cos(rot.x)*distance)
	self.position = pos

func mouse_first(mouse_vector : Vector3) -> void:
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
				if direction.y >= Constants.ROT_DIR_MAX and mouse_vector.y < 0:
					mouse_vector.y = 0
				elif direction.y <= -Constants.ROT_DIR_MAX and mouse_vector.y > 0:
					mouse_vector.y = 0
				self.rotate(Vector3.UP, mouse_vector.x)
				self.rotate(self.transform.basis.x.normalized(),mouse_vector.y)
			MouseDragMode.ZOOM:
				self.translate(Vector3(0,0,mouse_vector.y))
func mouse_third(mouse_vector : Vector3) -> void:
	if not mouse_vector.is_equal_approx(Vector3(0,0,0)):
		mouse_vector_sum -= mouse_vector
		match mouse_drag_mode:
			MouseDragMode.IDLE:
				pass
			MouseDragMode.MOVE:
				move_spd=Vector3(0,0,0)
				cursor_pivot.translate(self.global_basis*mouse_vector)
			MouseDragMode.ROTATE:
				var direction = self.transform.basis.z.normalized()
				var distance = self.position.length()
				if direction.y >= Constants.ROT_DIR_MAX and mouse_vector.y < 0:
					mouse_vector.y = 0
				elif direction.y <= -Constants.ROT_DIR_MAX and mouse_vector.y > 0:
					mouse_vector.y = 0
				self.rotate(Vector3.UP, mouse_vector.x)
				self.rotate(self.transform.basis.x.normalized(),mouse_vector.y)
				var rot = self.global_rotation
				var pos = Vector3(sin(rot.y)*cos(rot.x)*distance,sin(-rot.x)*distance,cos(rot.y)*cos(rot.x)*distance)
				self.position = pos
			MouseDragMode.ZOOM:
				self.translate(Vector3(0,0,mouse_vector.y))

func render_cursor() -> void:
	var pos :Vector2 = unproject_position(cursor_pivot.global_position)
	if (cursor_pivot.global_position - self.global_position).dot(self.transform.basis.z.normalized()) <0:
		if pos.is_equal_approx(cursor_viewport_pos):
			pass
		else:
			cursor_viewport_pos_changed.emit(pos)
			cursor_viewport_pos = pos

func top_view_animation(delta : float) -> void:
	top_view_animation_progress -= delta
	var lerp_progress := (Constants.TOP_VIEW_ANIMATION_DURATION-top_view_animation_progress)/Constants.TOP_VIEW_ANIMATION_DURATION
	
	var camera_target_rotation := Quaternion.from_euler(Constants.TOP_VIEW_CAMERA_EULER_ANGLE)
	self.quaternion=self.quaternion.slerp(camera_target_rotation,lerp_progress)
	self.position = self.position.lerp(Constants.TOP_VIEW_CAMERA_POSITION, lerp_progress)
	cursor_pivot.position = cursor_pivot.position.lerp(Constants.TOP_VIEW_CURSOR_PIVOT_POSITION, lerp_progress)
	
	if top_view_animation_progress <0 :
		top_view_animation_ended.emit()


func _on_top_view_icon_button_pressed() -> void:
	top_view_animation_progress=Constants.TOP_VIEW_ANIMATION_DURATION
func _on_camera_lock_on_cursor_icon_button_pressed() -> void:
	perspective_first=not perspective_first
