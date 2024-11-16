extends CircuitComponent
class_name K513IP3

func _process_signal():
	pin(12).set_low()
	pin(24).set_high()
	var a = ((pin(2).high as int)) | ((pin(23).high as int)<<1) | ((pin(21).high as int)<<2) | ((pin(19).high as int)<<3) 
	var b  = ((pin(1).high as int)) | ((pin(22).high as int)<<1) | ((pin(20).high as int)<<2) | ((pin(18).high as int)<<3)
	var s =	((pin(6).high as int)) | ((pin(5).high as int)<<1) | ((pin(4).high as int)<<2) | ((pin(3).high as int)<<3)
	var carry_out = false
	var cc = false # If only i knew what this is
	var m = pin(8).high
	var c = pin(7).high
	var f = 0 # Function result
	if not m: # I stole this part from the original TVB and removed "case" and "break"
		match s:
			0:
				f = a
			1:
				f = a | b
			2:
				f = a | (~b);
				
			3:
				f = -1;
				
			4:
				f = a + (a & (~b));
				cc = 1;
				
			5:
				f = (a & (~b)) + (a | b);
				
			6:
				f = a - b - 1;
				carry_out = 1;
				
			7:
				f = (a & (~b)) - 1;
				
			8:
				f = a + (a & b);
				
			9:
				f = a + b;
				
			10:
				f = (a & b) + (a | (~b));
				cc = 1;
				
			11:
				f = (a & b) - 1;
				
			12:
				f = a + a & (2 * a);
				
			13:
				f = a + (a | b);
				cc = 1;
				
			14:
				f = a + (a | (~b));
				cc = 1;
				
			15:
				f = a - 1;
			
		if(c):
			f+=1
	else:
		match (s) :
			0:
				f = ~a;
				
			1:
				f = ~(a | b);
				
			2:
				f = (~a) & b;
				
			3:
				f = 0;
				
			4:
				f = ~(a & b);
				
			5:
				f = ~b;
				
			6:
				f = (~a) & b | a & (~b);
				
			7:
				f = a & (~b);
				
			8:
				f = (~a) | b;
				
			9:
				f = a & b | (~a) & (~b);
				
			10:
				f = b;
				
			11:
				f = a & b;
				
			12:
				f = 1;
				
			13:
				f = a | (~b);
				
			14:
				f = a | b;
				
			15:
				f = a;
	pin(14).state = a==b# Write comparator output
	if((not cc) and (f & 16)) or carry_out:
		pin(16).set_high() # Set the carry output
	else:
		pin(16).set_low()
		
	write_output(f)

func write_output(f:int):
	pin(9).state = f & 1
	pin(10).state = f & (1<<1)!=0
	pin(11).state = f & (1<<2)!=0
	pin(13).state = f & (1<<3)!=0
