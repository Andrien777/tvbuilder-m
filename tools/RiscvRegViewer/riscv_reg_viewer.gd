extends Window

var proc: RV32
var reg_labels:Array[Label]
@onready var reg_grid:GridContainer = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/RegGridContainer")
@onready var reg_pc:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/ProgramCounterLabel")

func bind_proc(p:RV32):
	proc = p

func _ready():
	for i in range(32):
		var label = Label.new()
		label.text = "x%d: UNDEFINED" % [i]
		reg_labels.append(label)
		reg_grid.add_child(label)

func update_labels(values: Array[int], pc:int):
	reg_pc.text = "pc: %x" % [pc]
	for i in range(32):
		reg_labels[i].text = "x%d: %x" % [i, values[i]]
	
func _on_mem_viewer_button_pressed():
	OS.alert("Not implemented yet", "sorry")

func _on_close_requested() -> void:
	self.hide()
