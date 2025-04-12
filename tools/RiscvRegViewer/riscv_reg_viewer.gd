extends Window

const abi_names = {
	"x0": "zero",
	"x1": "ra",
	'x2': 'sp',
	'x3': 'gp',
	'x4': 'tp',
	'x5': 't0',
	'x6': 't1',
	'x7': 't2',
	'x8': 's0',
	'x9': 's1',
	'x10': 'a0',
	'x11': 'a1',
	'x12': 'a2',
	'x13': 'a3',
	'x14': 'a4',
	'x15': 'a5',
	'x16': 'a6',
	'x17': 'a7',
	'x18': 's2',
	'x19': 's3',
	'x20': 's4',
	'x21': 's5',
	'x22': 's6',
	'x23': 's7',
	'x24': 's8',
	'x25': 's9',
	'x26': 's10',
	'x27': 's11',
	'x28': 't3',
	'x29': 't4',
	'x30': 't5',
	'x31': 't6'
}

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
var addr_regex = RegEx.create_from_string("^[0-9A-Fa-f]{0,8}$")
@onready var seek_edit: LineEdit = get_node("TabContainer/Memory/VBoxContainer/HBoxContainer3/LineEdit")
@onready var batch_edit: LineEdit = $TabContainer/Main/ScrollContainer/VBoxContainer2/HBoxContainer/LineEdit
@onready var abi_toggle = $TabContainer/Main/ScrollContainer/VBoxContainer2/ABIModeButton
var abi_mode = true

func bind_proc(p:RV32):
	if not proc or proc != p:
		memory_page = 0
	proc = p
	$TabContainer/Memory/VBoxContainer/HBoxContainer2/RamNameLabel.text = "%s (%d)" % [proc.readable_name, proc.id]
	mem_viewer.memory = (proc.proc_impl.get_memory(memory_page * memory_page_size, memory_page_size))
	mem_viewer.display_page(memory_page)
	seek_edit.text = "%x" % (0x80000000 + memory_page * memory_page_size)
	$TabContainer/Memory/VBoxContainer/HBoxContainer/TextEdit.text = str(memory_page)
	$TabContainer/Main/ScrollContainer/VBoxContainer2/Button.reset_color()
	$TabContainer/Main/ScrollContainer/VBoxContainer2/Button2.reset_color()
	batch_edit.text = str(p.proc_impl.cycles_per_step)

func _ready():
	for i in range(32):
		var label = Label.new()
		label.add_theme_font_override("font", font)
		if abi_mode:
			label.text = "%4s: ????????" % [abi_names['x%d' % i]]
		else:
			if i < 10:
				label.text = "  x%d: ????????" % [i]
			else:
				label.text = " x%d: ????????" % [i]
		reg_labels.append(label)
		reg_grid.add_child(label)
	$TabContainer/Memory/VBoxContainer/HBoxContainer2/ContinuousUpdate.button_pressed = true
	$TabContainer.set_tab_title(0,"Регистры")
	$TabContainer.set_tab_title(1,"Память")
	abi_toggle.button_pressed = abi_mode
	seek_edit.text_changed.connect(validate_seek_edit_text)
	seek_edit.text_submitted.connect(seek_mem)
	batch_edit.text_changed.connect(on_batch_text_update)

func on_batch_text_update(new_text:String):
	if new_text.is_valid_int():
		var batch = int(new_text)
		if batch > 0:
			proc.proc_impl.cycles_per_step = batch
		else:
			proc.proc_impl.cycles_per_step = 1
			batch_edit.text = "1"
	else:
		proc.proc_impl.cycles_per_step = 1
		batch_edit.text = "1"

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
	if abi_mode:
		for i in range(32):
			reg_labels[i].text = "%4s: %08x" % [abi_names['x%d' % i], values[i]]
	else:
		for i in range(32):
			if i < 10:
				reg_labels[i].text = "  x%d: %08x" % [i, values[i]]
			else:
				reg_labels[i].text = " x%d: %08x" % [i, values[i]]

func toggle_abi_mode():
	abi_mode = !abi_mode
	abi_toggle.button_pressed = abi_mode

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
	if abi_mode:
		for i in range(32):
			reg_labels[i].text = "%4s: ????????" % [abi_names['x%d' % i]]
	else:
		for i in range(32):
			if i < 10:
				reg_labels[i].text = "  x%d: ????????" % [i]
			else:
				reg_labels[i].text = " x%d: ????????" % [i]
	
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
	seek_edit.text = "%x" % (0x80000000 + memory_page * memory_page_size)
	$TabContainer/Memory/VBoxContainer/HBoxContainer/TextEdit.text = str(memory_page)

func _on_mem_load(path):
	proc.load_mem(path)
	$TabContainer/Main/ScrollContainer/VBoxContainer2/Button._on_successful_load()

func _on_dtb_load(path):
	proc.load_dtb(path)
	$TabContainer/Main/ScrollContainer/VBoxContainer2/Button2._on_successful_load()

func validate_seek_edit_text(text):
	var valid_substr = addr_regex.search(text)
	if not valid_substr:
		seek_edit.text = "%x" % (0x80000000 + memory_page * memory_page_size)
		return

func seek_mem(text):
	var addr = (text as String).hex_to_int()
	if addr < 0x80000000:
		seek_edit.text = "%x" % (0x80000000 + memory_page * memory_page_size)
		return
	else:
		var offset = addr - 0x80000000
		set_memory_page(floori(offset / memory_page_size))
