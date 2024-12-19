extends ItemList
var labels = []
var memory = null
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	for i in range(16):
		var label = Label.new()
		labels.append(label)
		#self.add_item(label)
		#add_child(label)
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func display_page(page:int):
	display(memory.memory_content)
func write_to_memory():
	pass
	
func display(memory):
	var i=0
	for l in labels:
		l.text = str(memory[i])
		i = i+1
