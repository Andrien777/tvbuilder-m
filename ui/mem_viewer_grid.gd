extends GridContainer

var stylebox_selected: StyleBoxFlat
var stylebox_weakly_selected: StyleBoxFlat
var stylebox_addr_selected: StyleBoxFlat
var stylebox_normal: StyleBoxFlat
var labels = []
var memory = null
var addr = []
var header = []
var font = preload("res://ui/JetBrainsMonoNL-Regular.ttf")
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	stylebox_normal = StyleBoxFlat.new()
	stylebox_normal.bg_color = Color("4d4d4d")
	stylebox_selected = StyleBoxFlat.new()
	stylebox_selected.bg_color = Color("000000")
	stylebox_weakly_selected = StyleBoxFlat.new()
	stylebox_weakly_selected.bg_color = Color("3d3d3d")
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
				labels.append(label) # Value label
				label.add_theme_stylebox_override("normal", stylebox_normal)
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				label.connect("mouse_entered", func(): 
					header[i].add_theme_stylebox_override("normal", stylebox_addr_selected)
					addr[j].add_theme_stylebox_override("normal", stylebox_addr_selected)
					for _i in range(j):
						labels[16 * _i + i - 1].add_theme_stylebox_override("normal", stylebox_weakly_selected)
					for _j in range(i):
						labels[16 * j + _j].add_theme_stylebox_override("normal", stylebox_weakly_selected)
					label.add_theme_stylebox_override("normal", stylebox_selected))
				label.connect("mouse_exited", func(): 
					header[i].add_theme_stylebox_override("normal", stylebox_normal)
					addr[j].add_theme_stylebox_override("normal", stylebox_normal)
					for _i in range(j):
						labels[16 * _i + i - 1].add_theme_stylebox_override("normal", stylebox_normal)
					for _j in range(i):
						labels[16 * j + _j].add_theme_stylebox_override("normal", stylebox_normal))
			else:
				addr.append(label) # Address label
			add_child(label)
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func display_page(page: int):
	for i in range(len(addr)):
			addr[i].text = "%03x" % ((page*16 + i)*16)
	display(memory, page)

func write_to_memory():
	pass
	
func display(memory, page):
	var i=0
	for l in labels:
		if is_instance_valid(memory):
			if i + page * 16 * 16 < memory.memory_content.size():
				l.text = "%02x" % memory.memory_content[i + page * 16 * 16]
				i = i+1
			else:
				l.text = "??"
		else:
				l.text = "??"
