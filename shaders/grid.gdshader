shader_type canvas_item;
uniform vec2 position;
uniform vec2 scale = vec2(1,1);
uniform vec4 background_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 grid_color = vec4(0.4, 0.6, 0.9, 1.0);
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() { //or int(UV.y)%5==0
	if (int((UV.x*1.0/SCREEN_PIXEL_SIZE.x+position.x)/scale.x)%25<3 && int((UV.y*1.0/SCREEN_PIXEL_SIZE.y+position.y)/scale.y)%25<3){
		COLOR = background_color;
	}
	else{
		COLOR = grid_color;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
