extends Object

class_name CircuitComponentManager # TODO: think of a more suitable name 

var all_pins: Dictionary # I am unsure of where this should come from
func add_pin(pin: Pin):
	all_pins[pin] = null
func remove_pin(pin: Pin):
	all_pins.erase(pin)


func work_it_out() -> void:
	var graph_components = _init_graph_components()
	for component in graph_components:
		var pins = component.pins
		for pin in pins:
			# Если значение ножки не зависит от любого другого значения ножки,
			# то с неё можно начинать обход
			if !_is_dependent_on_anything(pin): 
				
				pass
			pass 
			
# А мне точно вообще нужны компоненты связности? Зачем я это делаю?
func _init_graph_components() -> Array[GraphComponent]:
	var graph_components: Array[GraphComponent]
	var visited_pins: Dictionary
	var visited_circuit_components: Dictionary
	for pin in all_pins: visited_pins[pin] = false
	
	for pin_index in range(all_pins.size()):
		if visited_pins[pin_index]: continue
		var current_component = GraphComponent.new()
		var pin = all_pins[pin_index]
		var queue: Array[Pin] = [pin]
		visited_pins[pin] = true
		while true:
			var current_pin = queue.pop_back()
			for new_pin in current_pin.connections_to + \
				current_pin.connections_from + \
				current_pin.parent.pins:
				if !visited_pins[new_pin]: 
					queue.push_back(new_pin)
					visited_pins[new_pin] = true
			
			current_component.append(current_pin)
			
		graph_components.append(current_component)
		
	return graph_components

func _is_dependent_on_anything(pin: Pin) -> bool:
	if (!pin.connections_to.is_empty()):
		return true
	for pin_ in pin.parent_circuit.pins:
		if !pin_.connections_to.is_empty():
			return true
	
	return false
