extends Window

var proc: RV32
var reg_labels:Array[Label]
var font = preload("res://ui/JetBrainsMonoNL-Regular.ttf")
@onready var reg_grid:GridContainer = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/RegGridContainer")
@onready var reg_pc:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/ProgramCounterLabel")
@onready var reg_mstatus:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mstatus")
@onready var reg_mie:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mie")
@onready var reg_mip:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mip")
@onready var reg_mepc:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mepc")
@onready var reg_tval:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_tval")
@onready var reg_mscratch:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mscratch")
@onready var reg_mtvec:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mtvec")
@onready var reg_mcause:Label = get_node("TabContainer/Main/ScrollContainer/VBoxContainer2/GridContainer/reg_mcause")
var continuous_memory_update = true
@onready var mem_viewer = $TabContainer/Memory/VBoxContainer/GridContainer
var memory_page = 0
var memory_page_size = 256

func bind_proc(p:RV32):
	proc = p
	$TabContainer/Memory/VBoxContainer/HBoxContainer2/RamNameLabel.text = "%s (%d)" % [proc.readable_name, proc.id]
	mem_viewer.memory = (proc.proc_impl.get_memory(memory_page * memory_page_size, memory_page_size))
	mem_viewer.display_page(memory_page)
	$TabContainer/Memory/VBoxContainer/HBoxContainer/TextEdit.text = str(memory_page)

func _ready():
	for i in range(32):
		var label = Label.new()
		label.add_theme_font_override("font", font)
		if i < 10:
			label.text = "x%d : ????????" % [i]
		else:
			label.text = "x%d: ????????" % [i]
		reg_labels.append(label)
		reg_grid.add_child(label)
	$TabContainer/Memory/VBoxContainer/HBoxContainer2/ContinuousUpdate.button_pressed = true
	$TabContainer.set_tab_title(0,"Регистры")
	$TabContainer.set_tab_title(1,"Память")
	

func _process(_delta):
	if visible:
		if proc:
			update_labels(proc.proc_impl.get_xreg(), proc.proc_impl.get_pc(), proc.proc_impl.get_mstatus(), proc.proc_impl.get_mie(), proc.proc_impl.get_mip(), 
			proc.proc_impl.get_mepc(), proc.proc_impl.get_mtval(), proc.proc_impl.get_mscratch(), proc.proc_impl.get_mtvec(), proc.proc_impl.get_mcause())
		else:
			reset_labels()
			$TabContainer/Memory/VBoxContainer/HBoxContainer2/RamNameLabel.text = "???"
			memory_update()
		if (continuous_memory_update and visible):
			memory_update()
			pass

func update_labels(values: Array, pc:int, mstatus:int, mie:int, mip:int, mepc:int, tval:int, mscratch:int, mtvec:int, mcause:int):
	reg_pc.text = "pc: %08x" % [pc]
	reg_mstatus.text = "mstatus: %08x" % [mstatus]
	reg_mie.text = "mie: %08x" % [mie]
	reg_mip.text = "mip: %08x" % [mip]
	reg_mepc.text = "mepc: %08x" % [mepc]
	reg_tval.text = "mtval: %08x" % [tval]
	reg_mscratch.text = "mscratch: %08x" % [mscratch]
	reg_mtvec.text = "mtvec: %08x" % [mtvec]
	reg_mcause.text = "mcause: %08x" % [mcause]
	for i in range(32):
		if i < 10:
			reg_labels[i].text = "x%d : %08x" % [i, values[i]]
		else:
			reg_labels[i].text = "x%d: %08x" % [i, values[i]]
		

func reset_labels():
	reg_pc.text = "pc: ????????"
	reg_mstatus.text = "mstatus: ????????"
	reg_mie.text = "mie: ????????"
	reg_mip.text = "mip: ????????"
	reg_mepc.text = "mepc: ????????"
	reg_tval.text = "mtval: ????????"
	reg_mscratch.text = "mscratch: ????????"
	reg_mtvec.text = "mtvec: ????????"
	reg_mcause.text = "mcause: ????????"
	for i in range(32):
		if i < 10:
			reg_labels[i].text = "x%d : ????????" % [i]
		else:
			reg_labels[i].text = "x%d: ????????" % [i]
	
func memory_update():
	if proc:
		$TabContainer/Memory/VBoxContainer/HBoxContainer2/RamNameLabel.text = "%s (%d)" % [proc.readable_name, proc.id]
		mem_viewer.memory = (proc.proc_impl.get_memory(memory_page * memory_page_size, memory_page_size))
		mem_viewer.display_page(memory_page)
	else:
		mem_viewer.memory = null
		mem_viewer.display_no_mem()

func _on_close_requested() -> void:
	self.hide()

func set_memory_page(page):
	memory_page = page
	memory_update()
	$TabContainer/Memory/VBoxContainer/HBoxContainer/TextEdit.text = str(memory_page)

func _on_mem_load(path):
	proc.load_mem(path)

func _on_dtb_load(path):
	proc.load_dtb(path)
