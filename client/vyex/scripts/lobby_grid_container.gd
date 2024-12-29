extends GridContainer

const PADDING = 20

func add_new_row(name : String, locked : bool, player1 : String, player2 : String) -> void:
	var pads : Array[Control] = []
	for i in range(0,7):
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
	if index+12 > child_count:
		push_error("delete_row : index out of range")
		return
	else:
		for i in range(13):
			var child = self.get_child(index*13)
			self.remove_child(child)
			child.queue_free()

func clear()->void:
	var child_count = self.get_child_count()
	for i in range(13,child_count):
		var child = self.get_child(13)
		self.remove_child(child)
		child.queue_free()
