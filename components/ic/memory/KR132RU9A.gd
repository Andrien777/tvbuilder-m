extends CircuitComponent
class_name KR132RU9A
var memory_content = Array()
var previous_state = false

func _init():
	memory_content.resize(1024);
	memory_content.fill(0);
	
var mem_viewer	
func _ready():
	mem_viewer = get_node("/root/RootNode/MemoryViewer")

func _rmb_action():
	mem_viewer.set_memory(self)


func initialize(spec: ComponentSpecification, ic = null):
	super.initialize(spec, ic)
	change_graphics_mode(GlobalSettings.GraphicsMode.Legacy if GlobalSettings.LegacyGraphics else GlobalSettings.GraphicsMode.Default)


func _process_signal():
	pin(9).set_low()
	pin(18).set_high()
	if (pin(8).low):
		var addr = get_addr()
		if((not previous_state) and pin(10).high):
			pin(11).set_output()
			pin(12).set_output()
			pin(13).set_output()
			pin(14).set_output()
		elif (previous_state and pin(10).low):
			pin(11).set_z()
			pin(12).set_z()
			pin(13).set_z()
			pin(14).set_z()
			pin(11).set_input()
			pin(12).set_input()
			pin(13).set_input()
			pin(14).set_input()
			
		if(pin(10).high):
			var values = get_values(addr)
			pin(14).state = values[0]
			pin(13).state = values[1]
			pin(12).state = values[2]
			pin(11).state = values[3]
		else:
			for i in range(0,4):
				if(not pin(11+i).z):
					set_value(addr, pin(11+i).high as int, 3-i)
				
		previous_state = pin(10).high
	else:
		pin(11).set_z()
		pin(12).set_z()
		pin(13).set_z()
		pin(14).set_z()

func get_addr():
	var addr =0 
	addr = addr | (pin(5).high as int )
	addr = addr | ((pin(6).high as int)<<1) 
	addr = addr | ((pin(7).high as int)<<2)
	addr = addr | ((pin(4).high as int)<<3)
	addr = addr | ((pin(3).high as int)<<4)
	addr = addr | ((pin(2).high as int)<<5)
	addr = addr | ((pin(1).high as int)<<6)
	addr = addr | ((pin(17).high as int)<<7)
	addr = addr | ((pin(16).high as int)<<8)
	addr = addr | ((pin(15).high as int)<<9)
	return addr

func set_value(addr:int, q:int, index:int):
	if(q==1):
		memory_content[addr] = memory_content[addr] | (q<<index) 
	else:
		memory_content[addr] = memory_content[addr] & (q<<index) 
	
func get_values(addr:int):
	var value = memory_content[addr]
	return [value & (1)!=0,value & (1<<1)!=0,value & (1<<2)!=0,value & (1<<3)!=0]

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)

	if(mode == GlobalSettings.GraphicsMode.Default):
		self.display_name_label = true
		name_label.visible = true
	elif (mode==GlobalSettings.GraphicsMode.Legacy):
		self.display_name_label = false
		name_label.visible = false
