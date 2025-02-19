extends CircuitComponent
class_name I8088
var proc_impl = IProc_8088.new();

var reg_viewer	
func _ready():
	proc_impl.ax = 0
	proc_impl.bx = 0
	proc_impl.cx = 0
	proc_impl.dx = 0
	reg_viewer = get_node("/root/RootNode/RegViewer")
	proc_impl.status = "OK"

func _rmb_action():
	reg_viewer.set_proc(self)

func set_io():
	for i in range(7, 15):
		if proc_impl.getPinOutputDisabled(i):
			pin(i + 2).set_input()
		else:
			pin(i + 2).set_output()


func write_pins():
	set_io()
	if pin(9).input():
		proc_impl.a7_pin = pin(9).high
	if pin(10).input():
		proc_impl.a6_pin =pin(10).high
	if pin(11).input():
		proc_impl.a5_pin = pin(11).high
	if pin(12).input():
		proc_impl.a4_pin = pin(12).high
	if pin(13).input():
		proc_impl.a3_pin = pin(13).high
	if pin(14).input():
		proc_impl.a2_pin = pin(14).high
	if pin(15).input():
		proc_impl.a1_pin = pin(15).high
	if pin(16).input():
		proc_impl.a0_pin = pin(16).high
	#proc_impl.nmi_pin = pin(17).high # Not implemented
	#proc_impl.intr_pin = pin(18).high # Not implemented
	proc_impl.clock_pin =pin(19).high
	proc_impl.rst_pin = pin(21).high
	proc_impl.rdy_pin = pin(22).high
	#proc_impl.test_pin = pin(23).high # Not implemented
	#proc_impl.hold_pin = pin(31).high # Not implemented
	proc_impl.mn_mx_pin = pin(33).high
	
func read_pins():
	set_io()
	pin(2).state = proc_impl.a14_pin
	pin(3).state = proc_impl.a13_pin
	pin(4).state = proc_impl.a12_pin
	pin(5).state = proc_impl.a11_pin
	pin(6).state = proc_impl.a10_pin
	pin(7).state = proc_impl.a9_pin
	pin(8).state = proc_impl.a8_pin
	
	if pin(9).output():
		pin(9).state = proc_impl.a7_pin
	if pin(10).output():
		pin(10).state = proc_impl.a6_pin
	if pin(11).output():
		pin(11).state = proc_impl.a5_pin
	if pin(12).output():
		pin(12).state = proc_impl.a4_pin
	if pin(13).output():
		pin(13).state = proc_impl.a3_pin
	if pin(14).output():
		pin(14).state = proc_impl.a2_pin
	if pin(15).output():
		pin(15).state = proc_impl.a1_pin
	if pin(16).output():
		pin(16).state = proc_impl.a0_pin
	#pin(24).state = proc_impl.inta_pin # Not implemented
	pin(25).state = proc_impl.ale_pin
	pin(26).state = proc_impl.den_pin
	pin(27).state = proc_impl.dt_nr_pin
	pin(29).state = proc_impl.wr_pin
	pin(32).state = proc_impl.rd_pin
	pin(28).state = proc_impl.io_np_pin # Not implemented
	#pin(34).state = proc_impl.ss0_pin # Not implemented
	pin(35).state = proc_impl.a19_pin
	pin(36).state = proc_impl.a18_pin
	pin(37).state = proc_impl.a17_pin
	pin(38).state = proc_impl.a16_pin
	pin(39).state = proc_impl.a15_pin
	pin(40).set_high() # VCC
	pin(20).set_low() # GND
func _process_signal():
	# Write all of the inputs to the IC implementation
	write_pins()
	proc_impl.Perform_work()
	read_pins()
	# Read the output
	if proc_impl.status != "OK":
		InfoManager.write_warning("Статус процессора: %s" % [proc_impl.status])
		proc_impl.status = "OK"
 
