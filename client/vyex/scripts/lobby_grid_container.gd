extends GridContainer

@onready var lobby_manager : Control = get_parent().get_parent().get_parent().get_parent()

const PADDING := 20
const COLUMNS := 13

func add_row(id: int, name : String, locked : bool, player1 : String, player2 : String) -> void:
	var pads : Array[Control] = []
	for i in 7:
		pads.append(Control.new())
		pads[i].custom_minimum_size.x=PADDING
	var locked_label : Label = Label.new()
	locked_label.text = "🔒" if locked else "🔓"
	var name_label : Label = Label.new()
	name_label.text = name
	var player1_label : Label = Label.new()
	player1_label.text = player1
	var player2_label : Label = Label.new()
	player2_label.text = player2
	var vs_label : Label = Label.new()
	vs_label.text = "vs"
	var join_button : Button = Button.new()
	join_button.text = "observe" if not player1.is_empty() and not player2.is_empty() else "join"
	var http_request : HTTPRequest = HTTPRequest.new()
	join_button.add_child(http_request)
	join_button.pressed.connect(func():
		lobby_manager._on_join_button_pressed(id, locked)
		)
	self.add_child(pads[0])
	self.add_child(locked_label)
	self.add_child(pads[1])
	self.add_child(name_label)
	self.add_child(pads[2])
	self.add_child(player1_label)
	self.add_child(pads[3])
	self.add_child(vs_label)
	self.add_child(pads[4])
	self.add_child(player2_label)
	self.add_child(pads[5])
	self.add_child(join_button)
	self.add_child(pads[6])

func delete_row(index : int)->void:
	var child_count = self.get_child_count()
	if index < 1 or index > child_count % COLUMNS:
		push_error("delete_row : index out of range ["+str(index)+"]")
		return
	else:
		for i in COLUMNS:
			var child = self.get_child(index*COLUMNS)
			self.remove_child(child)
			child.queue_free()

func move_row(from : int, to : int)->void:
	var child_count = self.get_child_count()
	if from < 1 or from > child_count % COLUMNS or to < 1 or to > child_count % COLUMNS:
		push_error("move_row : index out of range ["+str(from)+","+str(to)+"]")
		return
	else:
		for i in COLUMNS:
			var child = self.get_child((from+1)*COLUMNS-i)
			self.move_child(child,to*COLUMNS)

func clear()->void:
	var child_count = self.get_child_count()
	for i in range(COLUMNS,child_count):
		var child = self.get_child(COLUMNS)
		self.remove_child(child)
		child.queue_free()
