extends GridContainer

var stylebox_selected: StyleBoxFlat
var stylebox_weakly_selected: StyleBoxFlat
var stylebox_addr_selected: StyleBoxFlat
var stylebox_bold_selected:StyleBoxFlat
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
	stylebox_normal.bg_color = Color("2d2d2d")
	stylebox_selected = StyleBoxFlat.new()
	stylebox_selected.bg_color = Color("000000")
	stylebox_weakly_selected = StyleBoxFlat.new()
	stylebox_weakly_selected.bg_color = Color("3d3d3d")
	stylebox_addr_selected = StyleBoxFlat.new()
	stylebox_addr_selected.bg_color = Color("202020")
	stylebox_bold_selected = StyleBoxFlat.new()
	stylebox_bold_selected.bg_color = Color.ORANGE_RED
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
				labels.append(label) # Value label
				label.add_theme_stylebox_override("normal", stylebox_normal)
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				label.connect("mouse_entered", func(): 
					header[i].add_theme_stylebox_override("normal", stylebox_addr_selected)
					addr[j].add_theme_stylebox_override("normal", stylebox_addr_selected)
					for _i in range(j):
						if not labels[16 * _i + i - 1].get_theme_stylebox("normal")==stylebox_bold_selected:
							labels[16 * _i + i - 1].add_theme_stylebox_override("normal", stylebox_weakly_selected)
					for _j in range(i):
						if not labels[16 * j + _j].get_theme_stylebox("normal")==stylebox_bold_selected:
							labels[16 * j + _j].add_theme_stylebox_override("normal", stylebox_weakly_selected)
					if not label.get_theme_stylebox("normal")==stylebox_bold_selected:
						label.add_theme_stylebox_override("normal", stylebox_selected)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						label.add_theme_stylebox_override("normal", stylebox_bold_selected)
				)

				label.connect("mouse_exited", func(): 
					header[i].add_theme_stylebox_override("normal", stylebox_normal)
					addr[j].add_theme_stylebox_override("normal", stylebox_normal)
					for _i in range(j):
						if not labels[16 * _i + i - 1].get_theme_stylebox("normal")==stylebox_bold_selected:
							labels[16 * _i + i - 1].add_theme_stylebox_override("normal", stylebox_normal)
					for _j in range(i):
						if not labels[16 * j + _j].get_theme_stylebox("normal")==stylebox_bold_selected:
							labels[16 * j + _j].add_theme_stylebox_override("normal", stylebox_normal))
				label.connect("gui_input", func(event):
					if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
						if not label.get_theme_stylebox("normal")==stylebox_bold_selected:
							label.add_theme_stylebox_override("normal", stylebox_bold_selected)
						else:
							label.add_theme_stylebox_override("normal", stylebox_weakly_selected)
					)
			else:
				addr.append(label) # Address label
			add_child(label)
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func display_page(page: int):
	if previous_page != page and reset_styles_on_page_change:
		reset_all_labels_style()
	previous_page = page
	for i in range(len(addr)):
		addr[i].text = "%08x" % ((page*16 + i)*16 + 0x80000000)
	display()

func write_to_memory():
	pass
	
func display():
	var i=0
	for l in labels:
		if i < len(memory):
			l.text = "%02x" % memory[i]
			i = i+1
		else:
			l.text = "??"
		
func display_no_mem():
	reset_all_labels_style()
	for i in range(len(addr)):
		addr[i].text = "%03x" % (16*i)
	for l in labels:
		l.text = "??"

func reset_all_labels_style():
	for label in labels:
		label.add_theme_stylebox_override("normal", stylebox_normal)


func _on_reset_style_on_page_change_button_toggled(toggled_on: bool) -> void:
	reset_styles_on_page_change = toggled_on
