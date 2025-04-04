extends CircuitComponent
class_name TextLabel

var popup
var text_line
var label: Label
var popup_style
var portrait = preload("res://graphics/portrait.jpg")
var cat_tom = preload("res://graphics/cat_tom.jpg")
var cat_andr = preload("res://graphics/cat_andr.jpg")
var cat_nik = preload("res://graphics/cat_nik.jpg")
var portrait_sprite: Sprite2D
var cat_tom_sprite: Sprite2D
var cat_andr_sprite: Sprite2D
var cat_nik_sprite: Sprite2D

func initialize(spec: ComponentSpecification, ic=null)->void:
	if(ic!=null and "content" in ic):
		self.label.text = ic.content
	self.text_line.text = self.label.text
func _init():
	readable_name = "Метка"
	label = Label.new()
	label.text = "Метка"
	label.position = Vector2(0,0)
	label.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	label.add_theme_font_size_override("font_size",24)
	label.resized.connect(update_hibox)
	hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = label.get_rect().size
	hitbox.shape = shape
	hitbox.position = shape.size / 2
	self.input_pickable = true
	popup = Panel.new()
	popup.position = Vector2(0,0)
	text_line = LineEdit.new()
	text_line.size = Vector2(50,15)
	text_line.position = Vector2(10,10)
	text_line.context_menu_enabled = false
	#text_line.max_length = 3
	text_line.text = "Метка"
	#text_line.editable = false
	text_line.text_changed.connect(on_text_update)
	#text_line.position = Vector2(20,40)
	popup.visible = false
	popup_style = StyleBoxFlat.new()
	popup_style.bg_color =  Color.DIM_GRAY
	popup_style.bg_color.a = 0.9
	popup_style.set_corner_radius_all(15)
	popup.size =  Vector2(100,60)
	popup.add_theme_stylebox_override("panel", popup_style)

	portrait_sprite = Sprite2D.new()
	portrait_sprite.texture = portrait
	portrait_sprite.centered = false
	portrait_sprite.visible = false
	
	cat_tom_sprite = Sprite2D.new()
	cat_tom_sprite.texture = cat_tom
	cat_tom_sprite.centered = false
	cat_tom_sprite.visible = false
	
	cat_andr_sprite = Sprite2D.new()
	cat_andr_sprite.texture = cat_andr
	cat_andr_sprite.centered = false
	cat_andr_sprite.visible = false
	
	cat_nik_sprite = Sprite2D.new()
	cat_nik_sprite.texture = cat_nik
	cat_nik_sprite.centered = false
	cat_nik_sprite.visible = false
	#settings_popup.add_child(text_line)
	popup.add_child(text_line)
	add_child(popup)
	add_child(hitbox)
	add_child(label)
	add_child(portrait_sprite)
	add_child(cat_tom_sprite)
	add_child(cat_andr_sprite)
	add_child(cat_nik_sprite)
	portrait_sprite.visibility_changed.connect(update_hibox)
	cat_tom_sprite.visibility_changed.connect(update_hibox)
	cat_andr_sprite.visibility_changed.connect(update_hibox)
	cat_nik_sprite.visibility_changed.connect(update_hibox)
	
	#popup.get_parent().move_child(popup, -1)
	ComponentManager.register_object(self)
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if is_dragged && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#self.global_position = get_global_mouse_position() + drag_offset
	#else:
		#self.is_dragged = false
	#if Input.is_action_pressed("delete_component") and self.is_mouse_over:
		#Input.action_release("delete_component")
		##ComponentManager.remove_object(self)
		#queue_free()
		#
#var tween
func _input(event):
	if(popup.visible):
		pass
		
#func _process(delta: float) -> void:
	#if is_dragged && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#self.global_position = get_global_mouse_position() + drag_offset
	#else:
		#self.is_dragged = false
		#snap_to_grid()
	#if Input.is_action_pressed("delete_component") and self.is_mouse_over and popup.visible == false:
		#Input.action_release("delete_component")
		#ComponentManager.remove_object(self)
		#queue_free()
		#
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void: # TODO: Remove this overload
	super._input_event(viewport, event, shape_idx)
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		#popup.global_position = get_global_mouse_position()
		#popup.visible =!popup.visible
		#if(popup.visible):
			#GlobalSettings.disableGlobalInput = true
		#else:
			#GlobalSettings.disableGlobalInput = false
		get_node("/root/RootNode/UiCanvasLayer/GlobalInput").ask_for_input(
			"Текст метки", Callable(self, "on_text_update"), true, self.label.text)

	
		
func on_text_update(new_text:String):
	if(new_text!=""):
		var event = LabelTextChangeEvent.new()
		event.initialize(self, new_text)
		HistoryBuffer.register_event(event)
		label.text = new_text
		if new_text == "865933":
			label.visible = false
			portrait_sprite.visible = true
			cat_tom_sprite.visible = false
			cat_andr_sprite.visible = false
			cat_nik_sprite.visible = false
		elif new_text == "😺Катя":
			label.visible = false
			portrait_sprite.visible = false
			cat_tom_sprite.visible = true
			cat_andr_sprite.visible = false
			cat_nik_sprite.visible = false
		elif new_text == "😺Эля":
			label.visible = false
			portrait_sprite.visible = false
			cat_tom_sprite.visible = false
			cat_andr_sprite.visible = true
			cat_nik_sprite.visible = false
		elif new_text == "😺Мася":
			label.visible = false
			portrait_sprite.visible = false
			cat_tom_sprite.visible = false
			cat_andr_sprite.visible = false
			cat_nik_sprite.visible = true
		else:
			label.visible = true
			portrait_sprite.visible = false
			cat_tom_sprite.visible = false
			cat_andr_sprite.visible = false
			cat_nik_sprite.visible = false
		
		
	
func _exit_tree() -> void:
	self.name_label.queue_free()
	
	
#func _mouse_enter() -> void:
	#is_mouse_over = true
	#
#func _mouse_exit() -> void:
	#is_mouse_over = false
func to_json_object() -> Dictionary:
	return {
		"id": id,
		"name": readable_name,
		"position": position,
		"content": label.text
	}
func change_graphics_mode(mode):
	pass

func update_hibox():
	if portrait_sprite.visible:
		hitbox.shape.size = portrait.get_size()
		hitbox.position = hitbox.shape.size / 2
	elif cat_andr_sprite.visible:
		hitbox.shape.size = cat_andr.get_size()
		hitbox.position = hitbox.shape.size / 2
	elif cat_tom_sprite.visible:
		hitbox.shape.size = cat_tom.get_size()
		hitbox.position = hitbox.shape.size / 2
	elif cat_nik_sprite.visible:
		hitbox.shape.size = cat_nik.get_size()
		hitbox.position = hitbox.shape.size / 2
	else:
		hitbox.shape.size = label.get_rect().size
		hitbox.position = hitbox.shape.size / 2

func change_color():
	label.add_theme_color_override('font_color', GlobalSettings.label_color)
