extends CircuitComponent
class_name LED
var led_sprite: Sprite2D
var texture_on = preload("res://graphics/legacy/led/ld_up_green.png")
var texture_off = preload("res://graphics/legacy/led/ld_down_green.png")
func initialize(spec: ComponentSpecification)->void:
	self.display_name_label = false
	super.initialize(spec)
	#self.scale = Vector2(0.5,0.5)
	led_sprite = Sprite2D.new()
	if(!GlobalSettings.LegacyGraphics):
		led_sprite.texture = ic_texture
		led_sprite.modulate = Color(0, 100, 0, 0.2)
	else:
		led_sprite.texture = texture_off
		#led_sprite.scale = Vector2(2,2)
	add_child(led_sprite)

func _process(delta: float)->void:
	super._process(delta)
	if pins[0].state == NetConstants.LEVEL.LEVEL_HIGH:
		set_on()
	else:
		set_off()
		
		
func set_on():
	if GlobalSettings.LegacyGraphics:
		led_sprite.set_texture(texture_on)
		#self.sprite.texture = texture_up
	else:
		sprite.modulate = Color(0, 100, 0, 1)
		
func set_off():
	if GlobalSettings.LegacyGraphics:
		led_sprite.set_texture(texture_off)
		#self.sprite.texture = texture_down
	else:
		sprite.modulate = Color(0, 0, 0, 1)

func change_graphics_mode(mode:GlobalSettings.GraphicsMode):
	super.update_pins(self.pins, self.hitbox.shape.size)
	#super.change_graphics_mode(mode) 
	if(mode == GlobalSettings.GraphicsMode.Default):

		led_sprite.texture = ic_texture
		led_sprite.modulate = Color(0, 100, 0, 0.2)
	else:
		sprite.modulate = Color(1,1,1,1)
		led_sprite.modulate = Color(1, 1, 1, 1)
		led_sprite.texture = texture_off

	
