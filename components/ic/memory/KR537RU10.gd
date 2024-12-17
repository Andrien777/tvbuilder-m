extends CircuitComponent
class_name KR537RU10
var memory_content = Array()
var previous_state = false

var mem_viewer	
func _ready():
	mem_viewer = get_node("/root/RootNode/MemoryViewer")

func _rmb_action():
	mem_viewer.set_memory(self)
func _init():
	memory_content.resize(2048);
	memory_content.fill(0);	
	
func _process_signal():
	pin(12).set_low()
	pin(24).set_high()
	if (pin(18).low):
		var addr = get_addr()
		if((not previous_state) and pin(21).high):
			pin(9).set_output()
			pin(10).set_output()
			pin(11).set_output()
			pin(13).set_output()
			pin(14).set_output()
			pin(15).set_output()
			pin(16).set_output()
			pin(17).set_output()
		elif (previous_state and pin(21).low):
			pin(9).set_z()
			pin(10).set_z()
			pin(11).set_z()
			pin(13).set_z()
			pin(14).set_z()
			pin(15).set_z()
			pin(16).set_z()
			pin(17).set_z()
			pin(9).set_input()
			pin(10).set_input()
			pin(11).set_input()
			pin(13).set_input()
			pin(14).set_input()
			pin(15).set_input()
			pin(16).set_input()
			pin(17).set_input()
			
		if (pin(21).high_or_z and pin(20).low):
			var values = get_values(addr)
			pin(9).state = values[0]
			pin(10).state = values[1]
			pin(11).state = values[2]
			pin(13).state = values[3]
			pin(14).state = values[4]
			pin(15).state = values[5]
			pin(16).state = values[6]
			pin(17).state = values[7]
		elif (pin(21).high and pin(20).high_or_z):
			pin(9).set_z()
			pin(10).set_z()
			pin(11).set_z()
			pin(13).set_z()
			pin(14).set_z()
			pin(15).set_z()
			pin(16).set_z()
			pin(17).set_z()
		elif pin(21).low:
			if not pin(9).z: set_value(addr, pin(9).high as int, 0)
			if not pin(10).z: set_value(addr, pin(10).high as int, 1)
			if not pin(11).z: set_value(addr, pin(11).high as int, 2)
			if not pin(13).z: set_value(addr, pin(13).high as int, 3)
			if not pin(14).z: set_value(addr, pin(14).high as int, 4)
			if not pin(15).z: set_value(addr, pin(15).high as int, 5)
			if not pin(16).z: set_value(addr, pin(16).high as int, 6)
			if not pin(17).z: set_value(addr, pin(17).high as int, 7)
				
		previous_state = pin(21).high
	else:
		pin(9).set_z()
		pin(10).set_z()
		pin(11).set_z()
		pin(13).set_z()
		pin(14).set_z()
		pin(15).set_z()
		pin(16).set_z()
		pin(17).set_z()

func get_addr():
	var addr =0 
	addr = addr | (pin(19).high as int )
	addr = addr | ((pin(22).high as int)<<1) 
	addr = addr | ((pin(23).high as int)<<2)
	addr = addr | ((pin(1).high as int)<<3)
	addr = addr | ((pin(2).high as int)<<4)
	addr = addr | ((pin(3).high as int)<<5)
	addr = addr | ((pin(4).high as int)<<6)
	addr = addr | ((pin(5).high as int)<<7)
	addr = addr | ((pin(6).high as int)<<8)
	addr = addr | ((pin(7).high as int)<<9)
	addr = addr | ((pin(8).high as int)<<10)
	return addr

func initialize(spec: ComponentSpecification, ic = null):
	super.initialize(spec, ic)
	change_graphics_mode(GlobalSettings.GraphicsMode.Legacy if GlobalSettings.LegacyGraphics else GlobalSettings.GraphicsMode.Default)

func set_value(addr:int, q:int, index:int):
	if(q==1):
		memory_content[addr] = memory_content[addr] | (q<<index) 
	else:
		memory_content[addr] = memory_content[addr] & (q<<index) 
	
func get_values(addr:int):
	var value = memory_content[addr]
	return [value & (1)!=0,value & (1<<1)!=0,value & (1<<2)!=0,value & (1<<3)!=0,value & (1<<4)!=0,value & (1<<5)!=0,value & (1<<6)!=0,value & (1<<7)!=0]

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)

	if(mode == GlobalSettings.GraphicsMode.Default):
		self.display_name_label = true
		name_label.visible = true
	elif (mode==GlobalSettings.GraphicsMode.Legacy):
		self.display_name_label = false
		name_label.visible = false
