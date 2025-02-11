extends TabBar
var color_submenu
var general_submenu
var keybindings_submenu
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_submenu = get_node("./../ColorSubmenu")
	general_submenu = get_node("./../GeneralSettingsScroll")
	keybindings_submenu = get_node("./../KeyBindingsContainer")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_tab_changed(tab: int) -> void:
	if tab==0:
		color_submenu.hide()
		general_submenu.show()
		keybindings_submenu.hide()
	elif tab==1:
		color_submenu.show()
		general_submenu.hide()
		keybindings_submenu.hide()
	elif tab==2:
		color_submenu.hide()
		general_submenu.hide()
		keybindings_submenu.show()
