extends AcceptDialog

var signals_container: VBoxContainer

class CheckableSignal extends HBoxContainer:
	var sig: LA_signal
	var cb: CheckBox
	var label: Label
	
	func _init(sig: LA_signal):
		self.sig = sig
		
		var cb = CheckBox.new()
		cb.text = sig.line_edit.text
		self.cb = cb
		self.add_child(cb)


func _ready() -> void:
	var scroll_container = ScrollContainer.new()
	signals_container = VBoxContainer.new()
	
	scroll_container.add_child(signals_container)
	add_child(scroll_container)
	
	confirmed.connect(
		func():
			var signals: Array
			for child in signals_container.get_children():
				child = child as CheckableSignal
				if child.cb.button_pressed:
					signals.append(child.sig)
			if !signals.is_empty():
				%SignalsHSplitContainer.add_group(signals)
	)
	
func set_signals(signals: Array):
	for child in signals_container.get_children():
		child.queue_free()
	for sig in signals:
		var checkable_signal = CheckableSignal.new(sig)
		signals_container.add_child(checkable_signal)
