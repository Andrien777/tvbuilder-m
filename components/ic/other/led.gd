extends CircuitComponent
class_name LED
var led_sprite: Sprite2D
var texture_on = preload("res://graphics/legacy/led/ld_up_green.png")
var texture_off = preload("res://graphics/legacy/led/ld_down_green.png")
var default_texture  = preload("res://components/ic/ic2.svg")
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false
	
	
	led_sprite = Sprite2D.new()
	super.initialize(spec)
	led_sprite.position = sprite.texture.get_size() / 2
	if(GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		led_sprite.texture = ic_texture
		led_sprite.modulate = Color(0, 100, 0, 0.2)
	else:
		led_sprite.texture = texture_off
	
	add_child(led_sprite)

func _process(delta: float)->void:
	super._process(delta)
	if pins[0].state == NetConstants.LEVEL.LEVEL_HIGH:
		set_on()
	else:
		set_off()
		
		
func set_on():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		led_sprite.set_texture(texture_on)
	else:
		sprite.modulate = Color(0, 100, 0, 1)
		
func set_off():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		led_sprite.set_texture(texture_off)
	else:
		sprite.modulate = Color(0, 0, 0, 1)

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	if(mode == DefaultGraphicsMode):
		led_sprite.texture = ic_texture
		led_sprite.modulate = Color(0, 100, 0, 0.2)
	else:
		sprite.modulate = Color(1,1,1,1)
		led_sprite.modulate = Color(1, 1, 1, 1)
		led_sprite.texture = texture_off

	
