extends Camera3D

func _ready() -> void:
	pass

const MOVE_ACC = 1.0
const ROT_ACC = 0.2

const MOVE_SPD_MAX = 10.0
const ROT_SPD_MAX = 2.0

const MOVE_SPD_EPS = 1.1
const ROT_SPD_EPS = 0.21

const ROT_DIR_MAX = 0.9

var move_spd : Vector3 = Vector3(0,0,0)
var rot_spd : Vector2 = Vector2(0,0)

func _process(delta: float) -> void:
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
