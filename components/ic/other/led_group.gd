extends CircuitComponent
class_name LEDGroup

# -------------------------
# Config
# -------------------------
const MIN_LED_COUNT := 1
const MAX_LED_COUNT := 19

const POPUP_SIZE := Vector2(90, 50)
const POPUP_POS_TEXT := Vector2(10, 10)
const LABEL_POS := Vector2(0, 0)

const LED_OFF_MODULATE := Color(1, 1, 1, 1)
const LED_ON_MODULATE_DEFAULT := Color(0, 100, 0, 1)
const LED_OFF_MODULATE_DEFAULT := Color(0, 0, 0, 1)
const LED_DIM_MODULATE_DEFAULT := Color(0, 100, 0, 0.2)

const POPUP_COLOR_OK := Color.DIM_GRAY
const POPUP_COLOR_ERROR := Color.BROWN

# -------------------------
# Assets
# -------------------------
var texture_on := preload("res://graphics/legacy/led/ld_up_green.png")
var texture_off := preload("res://graphics/legacy/led/ld_down_green.png")
var default_texture := preload("res://components/ic/ic2.svg")

# -------------------------
# State
# -------------------------
var led_container: Node2D
var led_sprites: Array[Sprite2D] = []

var led_count: int = 0

var component_spec: ComponentSpecification
var pin_template: PinSpecification

# Base body size (used to scale width as count changes)
var base_pin_count: int = 8
var base_body_width: float = 360.0
var base_body_height: float = 45.0

# -------------------------
# UI
# -------------------------
var settings_popup: Panel
var popup_style: StyleBoxFlat
var count_label: Label
var text_line: LineEdit
var popup_open_state: Dictionary = {}


# =========================================================
# Lifecycle
# =========================================================
func _init() -> void:
	display_name_label = false
	led_container = Node2D.new()

func initialize(spec: ComponentSpecification, ic = null) -> void:
	component_spec = spec
	pin_template = spec.pinSpecifications[0]
	
	component_spec.num_pins = spec.details.get("size", spec.num_pins)
	spec.details.size = component_spec.num_pins
	spec.num_pins = spec.details.size

	led_count = spec.num_pins

	super.initialize(spec, ic)

	_ensure_led_container()
	_rebuild_leds()
	_rebuild_pins_for_led_count(led_count)

func _ready() -> void:
	# initialize() может вызваться до _ready(), но контейнер/LED уже созданы — ок.
	_ensure_led_container()
	_build_ui()


# =========================================================
# UI
# =========================================================
func _build_ui() -> void:
	self.input_pickable = true

	settings_popup = Panel.new()
	settings_popup.size = POPUP_SIZE
	settings_popup.visible = false
	settings_popup.z_index = 5

	popup_style = StyleBoxFlat.new()
	_set_popup_color_ok()
	popup_style.bg_color.a = 0.9
	popup_style.set_corner_radius_all(15)
	settings_popup.add_theme_stylebox_override("panel", popup_style)

	text_line = LineEdit.new()
	text_line.context_menu_enabled = false
	text_line.max_length = 4
	text_line.text = str(led_count)
	text_line.position = POPUP_POS_TEXT
	text_line.z_index = 6
	text_line.text_changed.connect(_on_text_changed)
	text_line.text_submitted.connect(_on_text_submitted)
	settings_popup.add_child(text_line)

	count_label = Label.new()
	count_label.position = LABEL_POS
	_update_count_label()
	count_label.visible = GlobalSettings.CurrentGraphicsMode != LegacyGraphicsMode

	add_child(settings_popup)
	add_child(count_label)

func _set_popup_color_ok() -> void:
	if popup_style:
		popup_style.bg_color = POPUP_COLOR_OK

func _set_popup_color_error() -> void:
	if popup_style:
		popup_style.bg_color = POPUP_COLOR_ERROR

func _update_count_label() -> void:
	if count_label:
		count_label.text = "Количество: " + str(led_count)


# =========================================================
# Input
# =========================================================
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	super._input_event(viewport, event, shape_idx)

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		_toggle_popup()

func _toggle_popup() -> void:
	var will_open := not settings_popup.visible
	if will_open:
		settings_popup.global_position = get_global_mouse_position()
		settings_popup.visible = true
		popup_open_state = capture_history_state()
		GlobalSettings.disableGlobalInput = true
		_refresh_popup_lock_state()
	else:
		_commit_history_state_change()
		settings_popup.visible = false
		GlobalSettings.disableGlobalInput = false

func _refresh_popup_lock_state() -> void:
	var locked := _has_connected_wires()
	text_line.editable = !locked
	if locked:
		_set_popup_color_error()
	else:
		_set_popup_color_ok()

func _on_text_submitted(_text: String) -> void:
	_commit_history_state_change()
	settings_popup.visible = false
	GlobalSettings.disableGlobalInput = false
	text_line.release_focus()

func _on_text_changed(new_text: String) -> void:
	# Block resize if component has any connected wire
	if _has_connected_wires():
		_set_popup_color_error()
		_restore_text_line()
		return

	if not new_text.is_valid_int():
		_set_popup_color_error()
		return

	var new_count := int(new_text)
	if new_count < MIN_LED_COUNT or new_count > MAX_LED_COUNT:
		_set_popup_color_error()
		return

	_apply_led_count(new_count)
	_set_popup_color_ok()

func _restore_text_line() -> void:
	if not is_instance_valid(text_line):
		return
	text_line.set_block_signals(true)
	text_line.text = str(led_count)
	text_line.set_block_signals(false)

func capture_history_state() -> Dictionary:
	return {
		"count": led_count
	}

func apply_history_state(state: Dictionary) -> void:
	var target_count: int = int(clamp(int(state.get("count", led_count)), MIN_LED_COUNT, MAX_LED_COUNT))
	led_count = target_count
	_update_count_label()
	_rebuild_leds()
	_rebuild_pins_for_led_count(led_count)
	_restore_text_line()

func _commit_history_state_change() -> void:
	if popup_open_state.is_empty():
		return
	var new_state := capture_history_state()
	if popup_open_state != new_state:
		var event = ComponentStateChangeEvent.new()
		event.initialize(self, popup_open_state, new_state)
		HistoryBuffer.register_event(event)
	popup_open_state = {}


# =========================================================
# Core logic (count change)
# =========================================================
func _apply_led_count(new_count: int) -> void:
	if new_count == led_count:
		return

	led_count = new_count
	_update_count_label()

	_rebuild_leds()
	_rebuild_pins_for_led_count(led_count)

func _rebuild_pins_for_led_count(n: int) -> void:
	var new_specs := _make_pin_specs(n)
	component_spec.num_pins = n
	component_spec.details.size = n
	component_spec.pinSpecifications = new_specs
	rebuild_pins(new_specs)


# =========================================================
# Pins spec generation
# =========================================================
func _make_pin_specs(n: int) -> Array:
	var arr: Array = []
	for i in range(n):
		var ps := PinSpecification.new()
		var base := _base_pin_name(pin_template.readable_name)
		ps.initialize(
			i + 1,
			pin_template.direction,
			pin_template.position,
			"%s%d" % [base, i + 1],
			pin_template.description,
			[] # dependencies reset; иначе индексы легко ломаются при изменении размера
		)
		arr.append(ps)
	return arr
	
func _base_pin_name(_name: String) -> String:
	return _name.rstrip("0123456789").strip_edges()
	

# =========================================================
# Visuals (body + LEDs)
# =========================================================
func _ensure_led_container() -> void:
	if led_container.get_parent() == null:
		add_child(led_container)

func _rebuild_leds() -> void:
	_ensure_led_container()

	for c in led_container.get_children():
		c.queue_free()
	led_sprites.clear()

	for i in range(led_count):
		var s := Sprite2D.new()
		led_sprites.append(s)
		led_container.add_child(s)

	_update_body_size()
	_apply_led_layout_and_style()

func _apply_led_layout_and_style() -> void:
	if sprite == null or sprite.texture == null:
		return

	var step = sprite.texture.get_size().y
	var n = min(led_count, led_sprites.size())

	for i in range(n):
		var s := led_sprites[i]
		s.position = Vector2(step * 0.5 + i * step, step * 0.5)

		if GlobalSettings.CurrentGraphicsMode == DefaultGraphicsMode:
			s.texture = ic_texture
			s.modulate = LED_DIM_MODULATE_DEFAULT
		else:
			s.texture = texture_off
			s.modulate = LED_OFF_MODULATE

func _update_body_size() -> void:
	if sprite == null or sprite.texture == null or hitbox == null:
		return

	var tex_size = sprite.texture.get_size()
	var step = tex_size.y

	# Fallbacks (если по какой-то причине база не закэшилась)
	if base_pin_count <= 0:
		base_pin_count = component_spec.num_pins
	if base_body_width <= 0.0:
		base_body_width = tex_size.x
	if base_body_height <= 0.0:
		base_body_height = tex_size.y

	var target_w = base_body_width + float(led_count - base_pin_count) * step
	target_w = max(step, target_w)

	sprite.scale = Vector2(target_w / tex_size.x, 1.0)

	var rect := hitbox.shape as RectangleShape2D
	rect.size = Vector2(target_w, tex_size.y)
	hitbox.position = rect.size * 0.5

	update_pins(pins, rect.size)


# =========================================================
# Runtime
# =========================================================
func _process(delta: float) -> void:
	super._process(delta)

	var n = min(led_count, pins.size(), led_sprites.size())
	for i in range(n):
		if pins[i].high:
			_set_led_on(i)
		else:
			_set_led_off(i)

func _has_connected_wires() -> bool:
	for wire: Wire in WireManager.wires:
		if wire.first_object in pins or wire.second_object in pins:
			return true
	return false

func _set_led_on(i: int) -> void:
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		led_sprites[i].texture = texture_on
	else:
		led_sprites[i].modulate = LED_ON_MODULATE_DEFAULT

func _set_led_off(i: int) -> void:
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		led_sprites[i].texture = texture_off
	else:
		led_sprites[i].modulate = LED_OFF_MODULATE_DEFAULT


# =========================================================
# Graphics mode change
# =========================================================
func change_graphics_mode(mode) -> void:
	super.change_graphics_mode(mode)

	_update_body_size()

	if led_sprites.is_empty():
		return
	_apply_led_layout_and_style()

	# UI label visibility depends on graphics mode
	if is_instance_valid(count_label):
		count_label.visible = GlobalSettings.CurrentGraphicsMode != LegacyGraphicsMode
