extends Container

@onready var map_shape_grid_container : GridContainer = $MapShapeGridContainer
@onready var map_width_spinbox : SpinBox = $HBoxContainer2/MapWidthSpinBox
@onready var map_height_spinbox : SpinBox = $HBoxContainer2/MapHeightSpinBox
@onready var icon_floor := preload("res://assets/sprites/icon_floor.png")
@onready var icon_xaht_blue := preload("res://assets/sprites/icon_xaht_blue.png")
@onready var icon_vusu_blue := preload("res://assets/sprites/icon_vusu_blue.png")
@onready var icon_ewng_blue := preload("res://assets/sprites/icon_ewng_blue.png")
@onready var icon_yzav_blue := preload("res://assets/sprites/icon_yzav_blue.png")
@onready var icon_xaht_red := preload("res://assets/sprites/icon_xaht_red.png")
@onready var icon_vusu_red := preload("res://assets/sprites/icon_vusu_red.png")
@onready var icon_ewng_red := preload("res://assets/sprites/icon_ewng_red.png")
@onready var icon_yzav_red := preload("res://assets/sprites/icon_yzav_red.png")
@onready var icon_none := preload("res://assets/sprites/icon_none.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset()

func _reset() -> void:
	map_width_spinbox.value=7
	map_height_spinbox.value=7
	var children = map_shape_grid_container.get_children()
	for child in children:
		map_shape_grid_container.remove_child(child)
		child.queue_free()
	for i in 7:
		for j in 7:
			var option_button = OptionButton.new()
			option_button.add_icon_item(icon_floor,"")
			option_button.add_icon_item(icon_xaht_blue,"")
			option_button.add_icon_item(icon_vusu_blue,"")
			option_button.add_icon_item(icon_ewng_blue,"")
			option_button.add_icon_item(icon_yzav_blue,"")
			option_button.add_icon_item(icon_xaht_red,"")
			option_button.add_icon_item(icon_vusu_red,"")
			option_button.add_icon_item(icon_ewng_red,"")
			option_button.add_icon_item(icon_yzav_red,"")
			option_button.add_icon_item(icon_none,"")
			if i==0 and j==0:
				option_button.select(4)
			elif i==0 and j==2 or i==2 and j==0:
				option_button.select(2)
			elif i==1 and j==1:
				option_button.select(3)
			elif i==2 and j==2:
				option_button.select(1)
			elif i==4 and j==4:
				option_button.select(5)
			elif i==4 and j==6 or i==6 and j==4:
				option_button.select(6)
			elif i==5 and j==5:
				option_button.select(7)
			elif i==6 and j==6:
				option_button.select(8)
			elif i-j>=5 or j-i>=5:
				option_button.select(9)
			map_shape_grid_container.add_child(option_button)


func _on_map_size_reset_button_pressed() -> void:
	_reset()

func _on_map_width_spin_box_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_map_height_spin_box_value_changed(value: float) -> void:
	pass # Replace with function body.
