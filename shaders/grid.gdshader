shader_type canvas_item;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() { //or int(UV.y)%5==0)
	if (int(UV.x*1.0/SCREEN_PIXEL_SIZE.x)%25==0 || int(UV.y*1.0/SCREEN_PIXEL_SIZE.y)%25==0){
			COLOR = vec4(0.4, 0.6, 0.9, 1.0);
		}
		else{
			COLOR = vec4(0.2, 0.2, 0.2, 1.0);
		}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
