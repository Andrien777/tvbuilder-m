extends CircuitComponent
class_name RV32
var proc_impl = RVProc.new();
var prev_clk = NetConstants.LEVEL.LEVEL_LOW
@onready var reg_viewer = get_node("/root/RootNode/RiscVRegViewer")
var mem_path = null
var dtb_path = "res://sixtyfourmb.dtb"

func _ready():
	if dtb_path:
		var arr = FileAccess.get_file_as_bytes(dtb_path)
		proc_impl.Load_dtb(arr)
	
func _process_signal():
	if pin(1).high and pin(1).state != prev_clk:
		proc_impl.set_mmio(read_pins())
		proc_impl.Tick()
		write_pins(proc_impl.get_mmio())
	prev_clk = pin(1).state

func read_pins():
	return ((pin(3).high as int) << 1) | (pin(2).high as int)

func reset():
	proc_impl.Reset()
	var arr
	if mem_path:
		arr = FileAccess.get_file_as_bytes(mem_path)
		proc_impl.Load_mem(arr)
	if dtb_path:
		arr = FileAccess.get_file_as_bytes(dtb_path)
		proc_impl.Load_dtb(arr)

func write_pins(val):
	if val % 2:
		pin(5).set_high()
	else:
		pin(5).set_low()
	if val & 2:
		pin(4).set_high()
	else:
		pin(4).set_low()

func _rmb_action():
	reg_viewer.bind_proc(self)
	reg_viewer.show()

func load_mem(path):
	var arr = FileAccess.get_file_as_bytes(path)
	proc_impl.Load_mem(arr)
	mem_path = path

func load_dtb(path):
	var arr = FileAccess.get_file_as_bytes(path)
	proc_impl.Load_dtb(arr)
	dtb_path = path
