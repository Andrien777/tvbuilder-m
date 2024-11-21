extends CircuitComponent
class_name CONST_1

func _process_signal():
	pin(1).set_high()

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)

	if(mode == GlobalSettings.GraphicsMode.Default):
		self.display_name_label = true
		name_label.visible = true
	elif (mode==GlobalSettings.GraphicsMode.Legacy):
		self.display_name_label = false
		name_label.visible = false
