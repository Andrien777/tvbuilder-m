extends CircuitComponent
class_name LEDMatrix
var texture_on = preload("res://graphics/legacy/led/ld_up_green.png")
var texture_off = preload("res://graphics/legacy/led/ld_down_green.png")
var default_texture  = preload("res://components/ic/ic2.svg")
var sprite_arr = []
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false
	
	for i in range(16):
		var temp_arr = []
		for j in range(16):
			var led_sprite = Sprite2D.new()
			temp_arr.append(led_sprite)
		sprite_arr.append(temp_arr)
	super.initialize(spec)
	for i in range(16):
		for j in range(16):
			var led_sprite = sprite_arr[i][j]
			led_sprite.position = Vector2(texture_off.get_size().y / 2 + j * texture_off.get_size().y, texture_off.get_size().y / 2 + i * texture_off.get_size().y)
			if(GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
				led_sprite.texture = ic_texture
				led_sprite.modulate = Color(0, 100, 0, 0.2)
			else:
				led_sprite.texture = texture_off
			add_child(led_sprite)

func _process_signal():
	for i in range(16):
		if pins[i].high:
			for j in range(16):
				if pins[16 + j].high:
					set_on(i, j)
				else:
					set_off(i, j)

func set_on(i, j):
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		sprite_arr[i][j].set_texture(texture_on)
	else:
		sprite_arr[i][j].modulate = Color(0, 100, 0, 1)
		
func set_off(i, j):
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		sprite_arr[i][j].set_texture(texture_off)
	else:
		sprite_arr[i][j].modulate = Color(0, 0, 0, 1)

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	if(mode == DefaultGraphicsMode):
		for i in range(16):
			for j in range(16):
				sprite_arr[i][j].texture = ic_texture
				sprite_arr[i][j].modulate = Color(0, 100, 0, 0.2)
	else:
		for i in range(16):
			for j in range(16):
				sprite.modulate = Color(1,1,1,1)
				sprite_arr[i][j].modulate = Color(1, 1, 1, 1)
				sprite_arr[i][j].texture = texture_off
