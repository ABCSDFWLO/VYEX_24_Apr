extends Node3D

signal cursor_origin_ready(pos:Vector3)

@export var initial_state : Array[Array]
@onready var kann_resource := preload("res://scenes/kann.tscn")

const KANN_INNER_SIZE := 2.5
const KANN_OUTER_SIZE := 2.75

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var x_size := initial_state.size()
	var y_size := 0
	for i in range(x_size):
		var row = initial_state[i]
		if row == null:
			continue
		else:
			var y_temp_size := initial_state[i].size()
			if y_size<y_temp_size:
				y_size=y_temp_size
			for j in range(y_temp_size):
				var col = row[j]
				if col == null or col == false:
					continue;
				else:
					var kann_temp := kann_resource.instantiate()
					kann_temp.get_child((i+j)%2).visible=false
					kann_temp.position = Vector3(i,0,j)*KANN_OUTER_SIZE
					self.add_child(kann_temp)
	cursor_origin_ready.emit(Vector3(x_size-1,0,y_size-1)*0.5*KANN_OUTER_SIZE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
