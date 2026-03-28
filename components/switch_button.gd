extends StaticBody2D
class_name SwitchButton

var texture_up = preload("res://graphics/legacy/switch/sw_up.png")
var texture_down = preload("res://graphics/legacy/switch/sw_down.png")
var texture_default = preload("res://icon.svg")

var sprite: Sprite2D
var button_hitbox: CollisionShape2D

var parent_component
var index: int = -1       # -1 = одиночный (не групповой) режим


func initialize(parent_ref, i: int = -1) -> void:
	input_pickable = true
	parent_component = parent_ref
	index = i

	sprite = Sprite2D.new()
	sprite.texture = texture_down if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode else texture_default
	add_child(sprite)

	button_hitbox = CollisionShape2D.new()
	button_hitbox.shape = RectangleShape2D.new()
	add_child(button_hitbox)

	change_graphics_mode(GlobalSettings.CurrentGraphicsMode) # выставит масштаб/хитбокс/цвет


func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT):
		return

	viewport.set_input_as_handled()

	# Групповой режим
	if index >= 0 and parent_component != null and parent_component.on is Array:
		var si := _state_index()
		if si < 0 or si >= parent_component.on.size():
			return

		parent_component.on[si] = !parent_component.on[si]
		_apply_visual(parent_component.on[si])
		return

	# Одиночный режим
	if parent_component != null and typeof(parent_component.on) == TYPE_BOOL:
		parent_component.on = !parent_component.on
		_apply_visual(parent_component.on)


func _state_index() -> int:
	var count = parent_component.on.size()
	return (count - 1) - index


func _apply_visual(is_on: bool) -> void:
	if is_on:
		set_on()
	else:
		set_off()


func set_on() -> void:
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		sprite.texture = texture_up
	else:
		sprite.modulate = Color(0, 100, 0, 1)


func set_off() -> void:
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		sprite.texture = texture_down
	else:
		sprite.modulate = Color(100, 0, 0, 1)


func change_graphics_mode(mode) -> void:
	if mode == LegacyGraphicsMode:
		sprite.texture = texture_down
		sprite.scale = Vector2(1, 1)
		sprite.modulate = Color(1, 1, 1, 1)
	else:
		sprite.texture = texture_default
		sprite.scale = Vector2(0.25, 0.25)
		sprite.modulate = Color(0, 0, 0, 1)

	# хитбокс с учётом масштаба спрайта
	var shape := RectangleShape2D.new()
	shape.size = sprite.texture.get_size() * sprite.scale
	button_hitbox.shape = shape
	button_hitbox.position = Vector2.ZERO


	# восстановить правильное состояние (если есть родитель и индекс)
	if parent_component != null:
		if index >= 0 and parent_component.on is Array:
			var si := _state_index()
			if si >= 0 and si < parent_component.on.size():
				_apply_visual(parent_component.on[si])
		elif typeof(parent_component.on) == TYPE_BOOL:
			_apply_visual(parent_component.on)
