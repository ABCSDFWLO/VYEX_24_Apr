extends MeshInstance3D

var material : ShaderMaterial
var iteration : int = 0
var iterator : int = 0

const ANIMATE_OPACITY_ITERATION = 30
const ANIMATE_SCALE_MAX = 5

func _ready() -> void:
	material = self.material_override

func _process(delta: float) -> void:
	process_animate_opacity()

func ease_out(t:float) -> float:
	if t<0:
		return 0
	elif t>1:
		return 1
	else:
		return t * (2 - t)
	
func trans_cubic(t:float) -> float:
	if t<0:
		return 0
	elif t>1:
		return 1
	else:
		return t**3

func set_animate_opacity(iteration:int) -> void:
	self.iteration = iteration
	self.iterator = iteration

func process_animate_opacity()->void:
	if self.iterator > 0:
		var t0:float = 1.0 - 1.0*self.iterator/self.iteration
		var t:float = ease_out(trans_cubic(t0))
		print(str(iterator) + "/" + str(iteration) +":"+str(t))
		material.set("shader_parameter/alpha",1-0.5*t)
		var ts = ANIMATE_SCALE_MAX*t
		self.scale = Vector3(ts,ts,ts)
		self.iterator = self.iterator - 1
	else:
		material.set("shader_parameter/alpha",0)

func _on_sprite_3d_cursor_highlight() -> void:
	print("event occured : _on_sprite_3d_cursor_highlight")
	set_animate_opacity(ANIMATE_OPACITY_ITERATION)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("focus"):
		set_animate_opacity(ANIMATE_OPACITY_ITERATION)
