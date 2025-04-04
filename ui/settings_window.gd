extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_requested.connect(close)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_window():
	self.visible = true
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/DoCyclesButton").button_pressed = not GlobalSettings.doCycles
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/MinimalGraphics").button_pressed = not GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode

	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/WireSnapCheckButton").button_pressed = GlobalSettings.WireSnap

	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/ShowLastWireButton").button_pressed = GlobalSettings.showLastWire
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/HighlightOutPinsButton").button_pressed = GlobalSettings.highlightOutputPins
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/SettingsOverrideButton").button_pressed = GlobalSettings.allowSettingsOverride
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/confirmOnSaveButton").button_pressed = GlobalSettings.confirmOnSave
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/disableAutosaveButton").button_pressed = GlobalSettings.disableAutosave
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/HideTreeButton").button_pressed = not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").tree_visible
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/HideRibbonButton").button_pressed = not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/TPSContainer/TPSEdit").text = str(GlobalSettings.tps)
	get_node("VBoxContainer/ColorSubmenu/ColorContainer/ColorPickerButton").color = Color(get_node('/root/RootNode/GridSprite').modulate, 1)
	get_node("VBoxContainer/ColorSubmenu/WireColorContainer/WireColorPickerButton").color = GlobalSettings.wire_color
	get_node("VBoxContainer/GeneralSettingsScroll/GeneralSettingsContainer/TurboModeButton").button_pressed = GlobalSettings.turbo
	get_node("VBoxContainer/ColorSubmenu/WireHighlightColorContainer/WireHighlightColorPickerButton").color = GlobalSettings.highlightedWireColor
	get_node("VBoxContainer/ColorSubmenu/PinHighlightContainer/PinHighlightColorPickerButton").color = GlobalSettings.highlightedPinsColor
	get_node("VBoxContainer/ColorSubmenu/PinLAHighlightColorContainer/PinLAHighlightColorPickerButton").color = GlobalSettings.highlightedLAPinsColor
	get_node("VBoxContainer/ColorSubmenu/BusColorContainer/BusColorPicker").color = GlobalSettings.bus_color
	get_node("VBoxContainer/ColorSubmenu/HighlightedBusColorContainer/BusColorPicker").color = GlobalSettings.highlightedBusColor
	get_node("VBoxContainer/ColorSubmenu/LabelColorContainer/LabelColorPicker").color = GlobalSettings.label_color
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/BusModeKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/DeleteKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/ConfirmKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/ZoomInKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/ZoomOutKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/EndWireKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/SelectionModeKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/NormalModeKeyBinding/Button")._ready()
	get_node("VBoxContainer/KeyBindingsContainer/VBoxContainer/InfoModeKeyBinding/Button")._ready()


func close():
	GlobalSettings.save()
	hide()
