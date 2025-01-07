extends Node3D

signal cursor_origin_ready(pos:Vector3)

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
	Constants.Maal.XAHT_WHITE : preload("res://scenes/maal/xhat_white.tscn"),
	Constants.Maal.VUSU_WHITE : preload("res://scenes/maal/vusu_white.tscn"),
	Constants.Maal.EWNG_WHITE : preload("res://scenes/maal/ewng_white.tscn"),
	Constants.Maal.YZAV_WHITE : preload("res://scenes/maal/yzav_white.tscn"),
	Constants.Maal.XAHT_BLACK : preload("res://scenes/maal/xhat_black.tscn"),
	Constants.Maal.VUSU_BLACK : preload("res://scenes/maal/vusu_black.tscn"),
	Constants.Maal.EWNG_BLACK : preload("res://scenes/maal/ewng_black.tscn"),
	Constants.Maal.YZAV_BLACK : preload("res://scenes/maal/yzav_black.tscn"),
}

const MAAL_COUNT_MAX := {
	Constants.Maal.XAHT_WHITE : 1,
	Constants.Maal.VUSU_WHITE : 2,
	Constants.Maal.EWNG_WHITE : 1,
	Constants.Maal.YZAV_WHITE : 1,
	Constants.Maal.XAHT_BLACK : 1,
	Constants.Maal.VUSU_BLACK : 2,
	Constants.Maal.EWNG_BLACK : 1,
	Constants.Maal.YZAV_BLACK : 1,
}
var ref_pos_map := {}

func _ready() -> void:
	_render_map()
	_calc_cursor_origin()

func _render_map() -> void:
	var x_size := state_pann.size()
	var y_size := 0
	var maal_count := {
		Constants.Maal.XAHT_WHITE : 0,
		Constants.Maal.VUSU_WHITE : 0,
		Constants.Maal.EWNG_WHITE : 0,
		Constants.Maal.YZAV_WHITE : 0,
		Constants.Maal.XAHT_BLACK : 0,
		Constants.Maal.VUSU_BLACK : 0,
		Constants.Maal.EWNG_BLACK : 0,
		Constants.Maal.YZAV_BLACK : 0,
	}
	for i in x_size:
		var row = state_pann[i]
		if row == null or row.is_empty():
			continue
		else:
			var y_temp_size := state_pann[i].size()
			if y_size<y_temp_size:
				y_size=y_temp_size
			for j in y_temp_size:
				var col = row[j]
				var h = col%16
				if col == null or h == 0:
					continue
				else:
					for k in h:
						var kann_temp := kann_resource.instantiate()
						kann_temp.get_child((i+j+k)%2).visible=false
						var x = i*(Constants.KANN_WIDTH + Constants.KANN_MARGIN)
						var y = k*(Constants.KANN_HEIGHT + Constants.KANN_MARGIN)
						var z = j*(Constants.KANN_WIDTH + Constants.KANN_MARGIN)
						kann_temp.position = Vector3(x,y,z)
						ref_pos_map[kann_temp]=Vector3i(i,k,j)
						self.add_child(kann_temp)
					var maal : Constants.Maal = col - col%16 as Constants.Maal
					if maal and maal_count[maal] < MAAL_COUNT_MAX[maal]:
						maal_count[maal]+=1
						var maal_temp : StaticBody3D = maal_resource[maal].instantiate()
						var x = i*(Constants.KANN_WIDTH + Constants.KANN_MARGIN)
						var y = (h - 0.5)*Constants.KANN_HEIGHT + (h + 1)*Constants.KANN_MARGIN
						var z = j*(Constants.KANN_WIDTH + Constants.KANN_MARGIN)
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
	for i in x_size:
		var row = state_pann[i]
		if row == null or row.is_empty():
			continue
		else:
			var y_temp_size := state_pann[i].size()
			if y_size<y_temp_size:
				y_size=y_temp_size
	var x = (x_size - 1)*(Constants.KANN_WIDTH + Constants.KANN_MARGIN)*0.5
	var y = 0
	var z = (y_size - 1)*(Constants.KANN_WIDTH + Constants.KANN_MARGIN)*0.5
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
