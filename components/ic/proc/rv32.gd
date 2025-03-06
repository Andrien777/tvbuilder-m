extends CircuitComponent
class_name RV32
var proc_impl = RVProc.new();
var prev_clk = NetConstants.LEVEL.LEVEL_LOW

func _ready():
	var arr = FileAccess.get_file_as_bytes("res://baremetal.bin")
	proc_impl.Load_mem(arr)
	arr = FileAccess.get_file_as_bytes("res://sixtyfourmb.dtb")
	proc_impl.Load_dtb(arr)
	
func _process_signal():
	if pin(1).high and pin(1).state != prev_clk:
		proc_impl.Tick()
	prev_clk = pin(1).state
	if pin(2).high:
		InfoManager.write_info(str(proc_impl.Get_x1()))
