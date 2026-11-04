extends Node

# Run this once in Godot (e.g. by attaching it to a Node and running the scene)
# to instantly export a 512x512 Sci-Fi game icon into your project files.

func _ready() -> void:
	generate_app_icon()

func generate_app_icon() -> void:
	var img_size := 512
	var img := Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)
	
	# Colors matching your game
	var dark_bg := Color("#050817")
	var cyan := Color("#00E5FF")
	var magenta := Color("#FF35D3")
	var center_glow := Color("#FFFFFF")
	
	var center := Vector2(img_size / 2, img_size / 2)
	
	# 1. Draw Deep Space Background
	img.fill(dark_bg)
	
	# 2. Draw subtle background glow / stars manually onto the image pixels
	for y in range(img_size):
		for x in range(img_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Vignette / Outer shadow
			if dist > img_size * 0.42:
				var t = (dist - img_size * 0.42) / (img_size * 0.08)
				var current_color = img.get_pixel(x, y)
				img.set_pixel(x, y, current_color.lerp(Color.BLACK, clampf(t, 0.0, 1.0)))

	# Helper to draw filled circles onto the image (for portals and energy rings)
	img = draw_portal_on_image(img, Vector2(center.x, center.y - 80), magenta, 110)
	img = draw_portal_on_image(img, Vector2(center.x, center.y + 80), cyan, 110)
	
	# Save directly to project root as icon.png
	var err = img.save_png("res://icon.png")
	if err == OK:
		print("SUCCESS: Sci-Fi Game Icon generated and saved to res://icon.png!")
		print("You can now assign res://icon.png in Project Settings -> Application -> Config -> Icon.")
	else:
		print("ERROR: Failed to save icon.png.")

func draw_portal_on_image(img: Image, pos: Vector2, tint: Color, radius: float) -> Image:
	var width = img.get_width()
	var height = img.get_height()
	
	for y in range(height):
		for x in range(width):
			var p = Vector2(x, y)
			var d = p.distance_to(pos)
			
			if d <= radius * 1.5:
				var current = img.get_pixel(x, y)
				var factor = 1.0 - (d / (radius * 1.5))
				var add_color = Color(tint.r, tint.g, tint.b, tint.a * factor * 0.4)
				img.set_pixel(x, y, current.blend(add_color))
				
			if absf(d - radius) < 6.0:
				img.set_pixel(x, y, tint)
			elif d < radius * 0.3:
				img.set_pixel(x, y, Color.WHITE)
				
	return img
