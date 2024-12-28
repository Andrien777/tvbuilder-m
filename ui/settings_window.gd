extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_requested.connect(close)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_window():
	self.visible = true
	get_node("VBoxContainer/DoCyclesButton").button_pressed = not GlobalSettings.doCycles
	get_node("VBoxContainer/MinimalGraphics").button_pressed = not GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode
	get_node("VBoxContainer/ShowLastWireButton").button_pressed = GlobalSettings.showLastWire

func close():
	GlobalSettings.save()
	hide()
