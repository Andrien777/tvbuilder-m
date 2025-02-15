extends Node
# Netlist

signal scheme_processed

var paused = false
var timer: Timer

func pause():
	paused = true

func pause_time():
	paused = true
	timer.start()

func unpause():
	paused = false


var nodes: Dictionary # Pin -> NetlistNode

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(unpause)
	add_child(timer)

func add_connection(pin1: Pin, pin2: Pin) -> void:
	if pin1 == pin2:
		return
	if pin1 not in nodes.keys():
		var node = NetlistNode.new()
		node.initialize(pin1)
		nodes[pin1] = node
	if pin2 not in nodes.keys():
		var node = NetlistNode.new()
		node.initialize(pin2)
		nodes[pin2] = node
	nodes[pin1].neighbours.append(nodes[pin2])
	nodes[pin2].neighbours.append(nodes[pin1])
	
func delete_connection(pin1, pin2)->void:
	if nodes.has(pin1) and nodes.has(pin2):
		if nodes[pin2] in nodes[pin1].neighbours:
			nodes[pin1].neighbours.erase(nodes[pin2])
		if nodes[pin1] in nodes[pin2].neighbours:
			nodes[pin2].neighbours.erase(nodes[pin1])
		if nodes[pin1].neighbours.is_empty():
			nodes.erase(pin1)
		if nodes[pin2].neighbours.is_empty():
			nodes.erase(pin2)

func clear():
	nodes.clear()

func process_scheme():
	if !paused:
		if GlobalSettings.doCycles:
			propagate_signal()
			process_components()
		else:
			propagate_signal()
	ComponentManager.clear_deletion_queue()

func propagate_signal() -> void:
	if nodes.is_empty():
		return
	var visited: Dictionary
	var resolved: Array[NetlistNode]
	var processed_ics: Array[CircuitComponent]
	var late_propagation: Array[NetlistNode]
	var stack: Array[NetlistNode]
	var entry_outputs: Dictionary
	var resolved_d: Dictionary

	for key in nodes.keys(): #find first output
		if is_instance_valid(nodes[key].pin) and nodes[key].pin.output():
			entry_outputs[nodes[key]] = null

		
	while visited.size() != nodes.size():
		find_entry_output(entry_outputs, stack, visited)
		
		if(stack.is_empty()): # If there are no outputs, find anything
			find_any_entry(stack, visited)
		while not stack.is_empty():
			var current = stack.back()
			if resolved_d.has(current) or current in late_propagation: #TODO: 'in' is potentially time consuming
				stack.pop_back()
				continue
			if current not in visited.keys():
				visited[current] = 1
			else:
				visited[current] += 1
			if visited[current] > 3:
				if is_instance_valid(current.pin) and current.pin.input():
					resolve_input_loop_prof()
					var i = stack.size() - 2
					var found_out = false
					while stack[i] != current:
						if stack[i].pin.output():
							found_out = true
							break
						i -= 1
					if not found_out:
						current.pin.set_z()
						#resolved.append(current)
						resolved_d[current] = null
						stack.pop_back()
						continue
				#stack.pop_back()
				##late_propagation.append(current)
				#PopupManager.display_error("Не удалось просчитать данный компонент", "Мы очень пытались. Честно.", current.pin.global_position)
				##print("Could not resolve component:")
				##print(current)
				#continue
			if is_instance_valid(current.pin) and current.pin.output():
				if not current.pin.dependencies.is_empty() and not GlobalSettings.doCycles:
					var dependencies_resolved = true
					dependencies_resolved = resolve_dependencies(current, visited, resolved, resolved_d, late_propagation, stack)
					if dependencies_resolved:
						resolve_current_output(current,stack,resolved, resolved_d)
				else:
					if not GlobalSettings.doCycles and is_instance_valid(current.pin):
						if current.pin.parent.readable_name in ["Кварцевый резонатор", "Генератор частоты"] and current.pin.parent in processed_ics:
							pass
						else:
							current.pin.parent._process_signal()
							if current.pin.parent.readable_name in ["Кварцевый резонатор", "Генератор частоты"]:
								processed_ics.append(current.pin.parent)
					else:
						set_not_connected_dependencies(current)
						
					stack.pop_back()
					#resolved.append(current)
					resolved_d[current] = null
					push_neighbour_outputs(current, stack, resolved, resolved_d)
					
			elif current.pin.input():
				var counter = 0
				counter = count_neighbour_outputs(current, resolved, resolved_d) # Actually, count neighbour outputs AND resolved inputs
				if counter >= 2:
					late_propagation.append(current)
					stack.pop_back()
					push_neighbour_inputs(current,stack)
					continue
				resolve_current_input(current, late_propagation, resolved, resolved_d)
				if resolved_d.has(current) or current in late_propagation:
					stack.pop_back()
				push_all_neighbours(current, stack)
	if not late_propagation.is_empty():
		do_late_propagation(late_propagation, resolved, resolved_d)
	if not GlobalSettings.doCycles:
		scheme_processed.emit()

func find_entry_output(entry_outputs, stack, visited):
	#for key in nodes.keys(): #find first output
		#if nodes[key] not in visited:
			#stack.push_back(nodes[key])
			#break
	for node in entry_outputs:
		if node not in visited:
			stack.push_back(node)
		else:
			entry_outputs.erase(node) # TODO: May be concurrent modification depending on implementation
func find_any_entry(stack, visited):
	for key in nodes.keys():
		if nodes[key] not in visited:
			stack.push_back(nodes[key])
			break
func count_neighbour_outputs(current, resolved, resolved_d): # Actually, count neighbour outputs AND resolved inputs
	var counter = 0
	for neighbour in current.neighbours:
		if not is_instance_valid(neighbour.pin):
			continue
		if neighbour.pin.output():
			counter += 1
		elif neighbour.pin.input():
			if resolved_d.has(neighbour):
				counter += 1
		if counter >= 2:
			return counter
	return counter
func set_not_connected_dependencies(current):
	for dep in current.pin.dependencies:
		if not nodes.has(dep):
			dep.set_high()
func push_neighbour_inputs(current, stack):
	for neighbour in current.neighbours:
		if neighbour != current:
			stack.push_back(neighbour)
func push_all_neighbours(current, stack):
	for neighbour in current.neighbours:
		if neighbour != current:
			stack.push_back(neighbour)
func push_neighbour_outputs(current, stack, resolved, resolved_d):
	for neighbour in current.neighbours:
		if not is_instance_valid(neighbour.pin):
			continue
		if neighbour.pin.output():
			if resolved_d.has(neighbour) and neighbour.pin.state != current.pin.state:
				if not neighbour.pin.z and not current.pin.z:
					PopupManager.display_error("Короткое замыкание", "Соединены два выхода с разными сигналами", current.pin.global_position)
					#print("Two outputs short circuited")
		if neighbour != current:
			stack.push_back(neighbour)
func resolve_current_output(current,stack,resolved, resolved_d):
	current.pin.parent._process_signal()
	stack.pop_back()
	#resolved.append(current)
	resolved_d[current] = null
	for neighbour in current.neighbours:
		if not is_instance_valid(neighbour.pin):
			continue
		if neighbour.pin.output():
			if resolved_d.has(neighbour)  and neighbour.pin.state != current.pin.state:
				if not neighbour.pin.z and not current.pin.z:
					PopupManager.display_error("Короткое замыкание", "Соединены два выхода с разными сигналами", current.pin.global_position)
					#print("Two outputs short circuited")
		if neighbour != current:
			stack.push_back(neighbour)
func resolve_current_input(current, late_propagation, resolved,  resolved_d):
	for neighbour in current.neighbours:
		if not is_instance_valid(neighbour.pin):
			continue
		if neighbour in late_propagation:
			late_propagation.append(current)
			break
		if neighbour.pin.output():
			if resolved_d.has(neighbour) :
				current.pin.state = neighbour.pin.state
				#resolved.append(current)
				resolved_d[current] = null
				break
		elif neighbour.pin.input():
			if resolved_d.has(neighbour) :
				current.pin.state = neighbour.pin.state
				#resolved.append(current)
				resolved_d[current] = null
				break
func resolve_dependencies(current, visited, resolved, resolved_d, late_propagation, stack):
	var dependencies_resolved = true
	for dep in current.pin.dependencies:
		if nodes.has(dep):
			if nodes[dep] in visited:
				if visited.get(nodes[dep]) > 2:
					late_propagation.append(current)
					stack.pop_back()
					break
			if not resolved_d.has(nodes[dep]):
				dependencies_resolved = false
				stack.push_back(nodes[dep])
			if nodes[dep] in late_propagation:
				late_propagation.append(current)
				stack.pop_back()
				break
		else:
			dep.set_high()
	return dependencies_resolved
func resolve_input_loop_prof():
	pass
func do_late_propagation(late_propagation, resolved, resolved_d):
	for pin in late_propagation:
			if not is_instance_valid(pin.pin):
				continue
			if pin.pin.output() and not GlobalSettings.doCycles:
				pin.pin.parent._process_signal()
			else:
				var state = pin.neighbours[0].pin.state
				var ok = true
				for neighbour in pin.neighbours:
					if not is_instance_valid(neighbour.pin):
						continue
					if not resolved_d.has(neighbour):
						
						continue
					if neighbour.pin.state != state and neighbour.pin.state != NetConstants.LEVEL.LEVEL_Z :
						if state == NetConstants.LEVEL.LEVEL_Z:
							state = neighbour.pin.state
						else:
							ok = false
				if ok or pin.pin.parent.readable_name == "Резистор": #TODO: Change that...
					pin.pin.state = state
				else:
					PopupManager.display_error("Короткое замыкание", "В этом месте произошло КЗ", pin.pin.global_position)
					#print("Short circuit")
func process_components():
	for key in nodes.keys():
		if key.direction == NetConstants.DIRECTION.DIRECTION_INPUT_OUTPUT and not GlobalSettings.doCycles:
			key.parent._process_signal()
	if GlobalSettings.doCycles:
		for ic in ComponentManager.obj_list.values():
			ic._process_signal()

	scheme_processed.emit()

func get_json_adjacency():
	var visited: Array[Pin]
	var edges: Array[Dictionary]
	for node in nodes:
		visited.append(node)
		for neighbour in nodes[node].neighbours:
			if neighbour.pin in visited:
				continue
			var wire = WireManager.find_wire_by_ends(node, neighbour.pin)

			if wire: # This can happen if "invisible link" was created. For example, pins in a bus are connected this way
				edges.append({
					"from": {
						"ic": node.parent.id,
						"pin": node.index
					},
					"to": {
						"ic": neighbour.pin.parent.id,
						"pin": neighbour.pin.index
					},
					"wire":{
						"control_points":wire.control_points,
						"color":null
					}
				})
	return edges
