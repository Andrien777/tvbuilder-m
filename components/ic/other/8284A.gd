extends CircuitComponent
class_name _8284A

var counter_3=0
var counter_2=0
var osc
var prev_inner_clk=false
var inner_clk
var clk
var prev_clk = false
var inner_rdy
var sync_rdy = false
var final_rdy

func _process_signal():
	pin(18).set_high()
	pin(7).set_low()	
	osc = pin(17).high && pin(16).low_or_z
	if !osc:
		pin(12).set_high()
	else:
		pin(12).set_low()
	inner_clk = osc && pin(13).low || pin(14).high && pin(13).high
	#if pin(1).low_or_z:
	if inner_clk && !prev_inner_clk:
		counter_3 += 1
	clk = counter_3 == 2
	if (counter_3 == 3): counter_3 = 0
	prev_inner_clk = inner_clk
	inner_rdy = pin(4).high && pin(3).low || pin(6).high && pin(7).low
	if clk:
		pin(8).set_high()
	else:
		pin(8).set_low()
	if !clk && prev_clk:
		if pin(11).low:
			pin(10).set_high()
		else:
			pin(10).set_low()
	if clk && !prev_clk:
		#if pin(1).low_or_z:
		counter_2 += 1
		sync_rdy = inner_rdy
		if (final_rdy):
			pin(5).set_high()
		else:
			pin(5).set_low()
	final_rdy = inner_rdy && (pin(15).high || sync_rdy)
	if counter_2 == 1:
		pin(2).set_high()
	else:
		pin(2).set_low()
	if (counter_2 == 2): counter_2 = 0
	prev_clk = clk
		
