extends Button

func _ready() -> void:
	get_tree().create_timer(.01).timeout.connect(
		func():
			size.x = %SignalsHSplitContainer.split_offset
			custom_minimum_size.x = %SignalsHSplitContainer.split_offset
	)
	
	%SignalsHSplitContainer.drag_ended.connect(
		func():
			size.x = %SignalsHSplitContainer.split_offset
			custom_minimum_size.x = %SignalsHSplitContainer.split_offset
	)
	


func _on_button_up() -> void:
	var signals = %SignalsHSplitContainer.signals
	var filtered_signals = signals.filter(func(sig): return sig is LA_signal)
	%GroupSignalsAcceptDialog.set_signals(filtered_signals) 
	%GroupSignalsAcceptDialog.show()
