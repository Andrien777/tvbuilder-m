extends CheckBox


@onready var LA_window = get_node("../../..")
@onready var signals_container = %SignalsHSplitContainer


func _ready() -> void:
	# GlobalSettings initialize after ready() callback, thus init() should be called later 
	call_deferred("init")

func init():
	button_pressed = GlobalSettings.is_LA_always_on_top

func _on_pressed() -> void:
	GlobalSettings.is_LA_always_on_top = button_pressed
	GlobalSettings.save()
	LA_window.always_on_top = button_pressed
	 
