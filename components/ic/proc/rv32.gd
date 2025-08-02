extends CircuitComponent
class_name RV32
var proc_impl = RVProc.new();
var prev_clk = NetConstants.LEVEL.LEVEL_LOW
@onready var reg_viewer = get_node("/root/RootNode/RiscVRegViewer")
var mem_path = null
var dtb_path = "res://bin/sixtyfourmb.dtb"
var prev_mcause = 0

func _ready():
	if dtb_path:
		var arr = FileAccess.get_file_as_bytes(dtb_path)
		proc_impl.Load_dtb(arr)
	proc_impl.cycles_per_step = 1
	
func _process_signal():
	pin(34).set_low()
	pin(35).set_high()
	if pin(68).low:
		reset()
	else:
		if pin(1).high and pin(1).state != prev_clk:
			proc_impl.set_mmio(read_pins())
			proc_impl.Tick()
			write_pins(proc_impl.get_mmio())
		prev_clk = pin(1).state
	var mcause = proc_impl.get_mcause()
	if mcause != prev_mcause and mcause != 0:
		if mcause & 0x80000000:
			InfoManager.write_warning("Прерывание в процессоре RV32. mcause = %x, mtval = %x" % [mcause, proc_impl.get_mtval()])
		else:
			InfoManager.write_warning("TRAP в процессоре RV32. mcause = %x, mtval = %x" % [mcause, proc_impl.get_mtval()])
		prev_mcause = mcause
	elif mcause == 0:
		prev_mcause = 0

func read_pins():
	var ret = 0
	for i in range(32):
		ret |= (pin(33 - i).high as int) << i
	return ret

func reset():
	proc_impl.Reset()
	var arr
	if mem_path:
		arr = FileAccess.get_file_as_bytes(mem_path)
		proc_impl.Load_mem(arr)
	if dtb_path:
		arr = FileAccess.get_file_as_bytes(dtb_path)
		proc_impl.Load_dtb(arr)
	proc_impl.set_mmio(0)
	write_pins(0)
	prev_mcause = 0

func write_pins(val):
	for i in range(32):
		if val & (1 << i):
			pin(36 + i).set_high()
		else:
			pin(36 + i).set_low()

func _rmb_action():
	reg_viewer.bind_proc(self)
	reg_viewer.show()

func load_mem(path):
	var arr = FileAccess.get_file_as_bytes(path)
	proc_impl.Load_mem(arr)
	mem_path = path

func load_mem_from_bytes(arr):
	proc_impl.Load_mem(arr)

func load_dtb(path):
	var arr = FileAccess.get_file_as_bytes(path)
	proc_impl.Load_dtb(arr)
	dtb_path = path
	
func load_dtb_from_bytes(arr):
	proc_impl.Load_dtb(arr)
