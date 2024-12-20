extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_requested.connect(hide)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_window():
	self.visible = true
