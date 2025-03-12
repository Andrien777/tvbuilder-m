extends CircuitComponent
class_name Quartz
var freq_label = Label.new()
func _init():
	display_name_label = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.input_pickable = true
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		freq_label.modulate = Color.BLACK
	else:
		freq_label.modulate = Color.WHITE
	add_child(freq_label)
	pin(1).set_low()
	pin(2).set_high()

func initialize(spec: ComponentSpecification, ic = null)->void:
	freq_label.text = str(Engine.physics_ticks_per_second / 2) + " Гц"
	super.initialize(spec, ic)
	sprite.texture.normal_texture = null
	sprite.texture.specular_texture = null
	sprite.material.shader = preload("res://shaders/glare.gdshader")
	freq_label.position = hitbox.shape.size / 2 - freq_label.get_theme_default_font().get_string_size(freq_label.text) / 2

func _process(delta: float) -> void:
	super._process(delta)
	if GlobalSettings.turbo:
		freq_label.text = str(Engine.physics_ticks_per_second * 3 / 2) + " Гц"
		freq_label.position = hitbox.shape.size / 2 - freq_label.get_theme_default_font().get_string_size(freq_label.text) / 2
	else:
		freq_label.text = str(Engine.physics_ticks_per_second / 2) + " Гц"
		freq_label.position = hitbox.shape.size / 2 - freq_label.get_theme_default_font().get_string_size(freq_label.text) / 2

func _process_signal():
	if(pin(1).high):
		pin(1).set_low()
		pin(2).set_high()
	else:
		pin(1).set_high()
		pin(2).set_low()
		
func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	if mode==LegacyGraphicsMode:
		freq_label.modulate = Color.BLACK
		freq_label.position = hitbox.shape.size / 2 - freq_label.get_theme_default_font().get_string_size(freq_label.text) / 2
	elif mode==DefaultGraphicsMode:
		freq_label.modulate = Color.WHITE
		freq_label.position = hitbox.shape.size / 2 - freq_label.get_theme_default_font().get_string_size(freq_label.text) / 2
		
