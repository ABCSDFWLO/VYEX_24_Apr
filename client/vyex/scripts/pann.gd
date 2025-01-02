extends Node3D

signal cursor_origin_ready(pos:Vector3)

enum Maal {
	XAHT_WHITE=16, VUSU_WHITE=32, EWNG_WHITE=48, YZAV_WHITE=64,
	XAHT_BLACK=80, VUSU_BLACK=96, EWNG_BLACK=112, YZAV_BLACK=128,
	NONE=0,
}

@export var state_pann : Array[PackedByteArray] = [
	[65, 1, 33, 1, 1, 0, 0],
	[1, 49, 1, 1, 1, 1, 0],
	[33, 1, 17, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 81, 1, 97],
	[0, 1, 1, 1, 1, 113, 1],
	[0, 0, 1, 1, 97, 1, 129],
]
@onready var kann_resource := preload("res://scenes/kann.tscn")
@onready var maal_resource := {
	Maal.XAHT_WHITE : preload("res://scenes/maal/xhat_white.tscn"),
	Maal.VUSU_WHITE : preload("res://scenes/maal/vusu_white.tscn"),
	Maal.EWNG_WHITE : preload("res://scenes/maal/ewng_white.tscn"),
	Maal.YZAV_WHITE : preload("res://scenes/maal/yzav_white.tscn"),
	Maal.XAHT_BLACK : preload("res://scenes/maal/xhat_black.tscn"),
	Maal.VUSU_BLACK : preload("res://scenes/maal/vusu_black.tscn"),
	Maal.EWNG_BLACK : preload("res://scenes/maal/ewng_black.tscn"),
	Maal.YZAV_BLACK : preload("res://scenes/maal/yzav_black.tscn"),
}

const MAAL_COUNT_MAX := {
	Maal.XAHT_WHITE : 1,
	Maal.VUSU_WHITE : 2,
	Maal.EWNG_WHITE : 1,
	Maal.YZAV_WHITE : 1,
	Maal.XAHT_BLACK : 1,
	Maal.VUSU_BLACK : 2,
	Maal.EWNG_BLACK : 1,
	Maal.YZAV_BLACK : 1,
}
var ref_pos_map := {}

func _ready() -> void:
	_render_map()
	_calc_cursor_origin()

func _render_map() -> void:
	var x_size := state_pann.size()
	var y_size := 0
	var maal_count := {
		Maal.XAHT_WHITE : 0,
		Maal.VUSU_WHITE : 0,
		Maal.EWNG_WHITE : 0,
		Maal.YZAV_WHITE : 0,
		Maal.XAHT_BLACK : 0,
		Maal.VUSU_BLACK : 0,
		Maal.EWNG_BLACK : 0,
		Maal.YZAV_BLACK : 0,
	}
	for i in range(x_size):
		var row = state_pann[i]
		if row == null or row.is_empty():
			continue
		else:
			var y_temp_size := state_pann[i].size()
			if y_size<y_temp_size:
				y_size=y_temp_size
			for j in range(y_temp_size):
				var col = row[j]
				if col == null or col%16 == 0:
					continue;
				else:
					for k in col%16:
						var kann_temp := kann_resource.instantiate()
						kann_temp.get_child((i+j+k)%2).visible=false
						var x = i*Constants.KANN_OUTER_SIZE
						var y = k*Constants.KANN_HEIGHT_INTERVAL
						var z = j*Constants.KANN_OUTER_SIZE
						kann_temp.position = Vector3(x,y,z)
						ref_pos_map[kann_temp]=Vector3i(i,k,j)
						self.add_child(kann_temp)
					var maal : Maal = col - col%16
					if maal and maal_count[maal] < MAAL_COUNT_MAX[maal]:
						maal_count[maal]+=1
						var maal_temp : StaticBody3D = maal_resource[maal].instantiate()
						var x = i*Constants.KANN_OUTER_SIZE
						var y = (col%16)*Constants.KANN_HEIGHT_INTERVAL+Constants.MAAL_FLOOR_OFFSET
						var z = j*Constants.KANN_OUTER_SIZE
						maal_temp.position = Vector3(x,y,z)
						ref_pos_map[maal_temp]=Vector3i(i,col%16,j)
						self.add_child(maal_temp)
func _clear_map() -> void:
	for ref:Node in ref_pos_map.keys():
		remove_child(ref)
		ref.queue_free()
	ref_pos_map.clear()

func _calc_cursor_origin() -> void:
	var x_size := state_pann.size()
	var y_size := 0
	for i in range(x_size):
		var row = state_pann[i]
		if row == null or row.is_empty():
			continue
		else:
			var y_temp_size := state_pann[i].size()
			if y_size<y_temp_size:
				y_size=y_temp_size
	var x = (x_size-1)*Constants.KANN_OUTER_SIZE*0.5
	var y = 0
	var z = (y_size-1)*Constants.KANN_OUTER_SIZE*0.5
	cursor_origin_ready.emit(Vector3(x,y,z))

func get_pos_by_ref(ref:Object)->Vector3i:
	if ref in ref_pos_map.keys():
		return ref_pos_map[ref]
	else:
		return Vector3i(-1,-1,-1)

func _on_camera_3d_stack_wall(pos: Vector2i) -> void:
	state_pann[pos.x][pos.y]+=1
	_clear_map()
	_render_map()
