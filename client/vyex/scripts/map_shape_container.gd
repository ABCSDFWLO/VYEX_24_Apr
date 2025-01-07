extends Container

@onready var map_shape_grid_container : GridContainer = $MapShapeGridContainer
@onready var map_width_spinbox : SpinBox = $HBoxContainer2/MapWidthSpinBox
@onready var map_height_spinbox : SpinBox = $HBoxContainer2/MapHeightSpinBox

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
			option_button.add_item("FLOOR")
			for m in Constants.Maal.keys():
				option_button.add_item(m)
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
