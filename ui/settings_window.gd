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
	get_node("VBoxContainer/HighlightOutPinsButton").button_pressed = GlobalSettings.highlightOutputPins
	get_node("VBoxContainer/HideTreeButton").button_pressed = not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").tree_visible
	get_node("VBoxContainer/HideRibbonButton").button_pressed = not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible

func close():
	GlobalSettings.save()
	hide()
