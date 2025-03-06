extends Window

var proc: RV32
var reg_labels:Array[Label]
@onready var reg_grid:GridContainer = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/RegGridContainer")
@onready var reg_pc:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/ProgramCounterLabel")
@onready var reg_mstatus:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/GridContainer/reg_mstatus")
@onready var reg_mie:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/GridContainer/reg_mie")
@onready var reg_mip:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/GridContainer/reg_mip")
@onready var reg_mepc:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/GridContainer/reg_mepc")
@onready var reg_tval:Label = get_node("VBoxContainer/ScrollContainer/VBoxContainer2/GridContainer/reg_tval")

func bind_proc(p:RV32):
	proc = p

func _ready():
	for i in range(32):
		var label = Label.new()
		label.text = "x%d: ??" % [i]
		reg_labels.append(label)
		reg_grid.add_child(label)

func _process(_delta):
	if visible:
		if proc:
			update_labels(proc.proc_impl.get_xreg(), proc.proc_impl.get_pc(), proc.proc_impl.get_mstatus(), proc.proc_impl.get_mie(), proc.proc_impl.get_mip(), 
			proc.proc_impl.get_mepc(), proc.proc_impl.get_mtval())
		else:
			reset_labels()

func update_labels(values: Array, pc:int, mstatus:int, mie:int, mip:int, mepc:int, tval:int):
	reg_pc.text = "pc: %x" % [pc]
	reg_mstatus.text = "mstatus: %x" % [mstatus]
	reg_mie.text = "mie: %x" % [mie]
	reg_mip.text = "mip: %x" % [mip]
	reg_mepc.text = "mepc: %x" % [mepc]
	reg_tval.text = "mtval: %x" % [tval]
	for i in range(32):
		reg_labels[i].text = "x%d: %x" % [i, values[i]]

func reset_labels():
	reg_pc.text = "pc: ??"
	reg_mstatus.text = "mstatus: ??"
	reg_mie.text = "mie: ??"
	reg_mip.text = "mip: ??"
	reg_mepc.text = "mepc: ??"
	reg_tval.text = "mtval: ??"
	for i in range(32):
		reg_labels[i].text = "x%d: ??" % [i]
	
func _on_mem_viewer_button_pressed():
	OS.alert("Not implemented yet", "sorry")

func _on_close_requested() -> void:
	self.hide()
