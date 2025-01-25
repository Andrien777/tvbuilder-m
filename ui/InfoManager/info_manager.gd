extends Node
var console = null
var indicator = null
var unread_counter=0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func bind_console(console:Control):
	self.console = console
func bind_indicator(indicator:Control):
	self.indicator = indicator

func write_error(text):
	if(console):
		console.write(text, Color.RED, '(E)')
		if not console.visible:
			unread_counter+=1
			indicate_error()
		else:
			unread_counter=0
	else:
		pass # TODO: Write to logfile

func write_warning(text):
	if(console):
		console.write(text, Color.DARK_ORANGE, '(W)')
		if not console.visible:
			unread_counter+=1
			indicate_warning()
		else:
			unread_counter=0
	else:
		pass # TODO: Write to logfile

func write_info(text):
	if(console):
		console.write(text, Color.AQUA, '(I)')
		if not console.visible:
			unread_counter+=1
		else:
			unread_counter=0
	else:
		pass # TODO: Write to logfile
func toggle_console():
	if console:
		if console.visible:
			hide_console()
		else:
			show_console()

func hide_console():
	if console:
		console.hide()
func show_console():
	if console:
		unread_counter = 0
		console.show()
		
func indicate_warning():
	if indicator and indicator.player:
		indicator.player.play('button_pulse_yellow')
func indicate_error():
	if indicator and indicator.player:
		indicator.player.play('button_pulse_red')
