extends GridContainer

var stylebox_addr_selected: StyleBoxFlat
var stylebox_normal: StyleBoxFlat
var reset_styles_on_page_change = true
var labels = []
var memory = null
var addr = []
var header = []
var previous_page
var font = preload("res://ui/JetBrainsMonoNL-Regular.ttf")
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	stylebox_normal = StyleBoxFlat.new()
	stylebox_normal.bg_color = Color("4d4d4d")
	stylebox_addr_selected = StyleBoxFlat.new()
	stylebox_addr_selected.bg_color = Color("202020")
	for i in range(17): # Creating the table header
		var label = Label.new()
		label.add_theme_font_override("font", font)
		if i>0:
			label.text = "%2x" % (i-1)
		header.append(label)
		add_child(label)
	for j in range(16):
		for i in range(17):
			var label = Label.new()
			label.add_theme_font_override("font", font)
			if i>0:
				label.queue_free()
				label = MemCell.new()
				labels.append(label) # Value label
				label.mouse_enter.connect(_on_label_mouse_enter.bind(i, j))
				label.mouse_exit.connect(_on_label_mouse_exit.bind(i, j))
				label.content_changed.connect(write_to_memory)
				label.is_4bit = true
			else:
				addr.append(label) # Address label
			add_child(label)
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_label_mouse_enter(i, j):
	header[i].add_theme_stylebox_override("normal", stylebox_addr_selected)
	addr[j].add_theme_stylebox_override("normal", stylebox_addr_selected)
	for _i in range(j):
		labels[16 * _i + i - 1].set_weak_select()
	for _j in range(i):
		labels[16 * j + _j].set_weak_select()

func _on_label_mouse_exit(i, j):
	header[i].add_theme_stylebox_override("normal", stylebox_normal)
	addr[j].add_theme_stylebox_override("normal", stylebox_normal)
	for _i in range(j):
		if not labels[16 * _i + i - 1].is_selected():
			labels[16 * _i + i - 1].reset_select()
	for _j in range(i):
		if not labels[16 * j + _j].is_selected():
			labels[16 * j + _j].reset_select()

func display_page(page: int):
	if previous_page != page and reset_styles_on_page_change:
		reset_all_labels_style()
	previous_page = page
	for i in range(len(addr)):
			addr[i].text = "%03x" % ((page*16 + i)*16)
	display(memory, page)

func write_to_memory(addr, value):
	memory.memory_content[addr] = value
	
func display(memory, page):
	var i=0
	for l in labels:
		if is_instance_valid(memory):
			if i + page * 16 * 16 < memory.memory_content.size():
				l.content = memory.memory_content[i + page * 16 * 16]
				l.addr = i + page * 16 * 16
				i = i+1
			else:
				l.content = -1
		else:
				l.content = -1

func reset_all_labels_style():
	for label in labels:
		label.reset_select()


func _on_reset_style_on_page_change_button_toggled(toggled_on: bool) -> void:
	reset_styles_on_page_change = toggled_on
