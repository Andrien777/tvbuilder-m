extends GridContainer


var labels = []
var memory = null
var addr = []
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	for i in range(17): # Creating the table header
		var label = Label.new()
		if i>0:
			label.text = "%2x" % (i-1)
		add_child(label)
	for j in range(16):
		for i in range(17):
			var label = Label.new()
			if i>0:
				labels.append(label) # Value label
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
	if(page*16*16+17*16<len(memory.memory_content) and page>=0):
		display(memory.memory_content.slice(page*16*16, page*16*16+17*16))
	else:
		for l in labels:
			l.text = "?"

func write_to_memory():
	pass
	
func display(memory):
	var i=0
	for l in labels:
		l.text = "%02x" % memory[i]
		i = i+1
