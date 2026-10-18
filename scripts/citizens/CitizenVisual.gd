
extends Node2D

# ZekaCity - CitizenVisual.gd
# Godot 3.6
# Isometric 2.5D citizen visual

var animation_time = 0.0
var skin_seed = 0
var shirt_color = Color(0.20, 0.48, 0.82)
var pants_color = Color(0.16, 0.20, 0.28)
var skin_color = Color(0.91, 0.69, 0.52)
var hair_color = Color(0.20, 0.14, 0.10)


func setup(seed_value = 0):
	skin_seed = abs(int(seed_value))

	var shirts = [
		Color(0.20, 0.48, 0.82),
		Color(0.78, 0.28, 0.22),
		Color(0.22, 0.58, 0.38),
		Color(0.78, 0.58, 0.18),
		Color(0.54, 0.32, 0.72),
		Color(0.78, 0.78, 0.72)
	]

	var skins = [
		Color(0.91, 0.69, 0.52),
		Color(0.72, 0.48, 0.33),
		Color(0.96, 0.78, 0.63),
		Color(0.56, 0.36, 0.25)
	]

	shirt_color = shirts[skin_seed % shirts.size()]
	skin_color = skins[int(skin_seed / 2) % skins.size()]

	if skin_seed % 2 == 0:
		hair_color = Color(0.20, 0.14, 0.10)
	else:
		hair_color = Color(0.38, 0.25, 0.15)

	pants_color = Color(0.16, 0.20, 0.28)

	set_process(true)
	update()


func _process(delta):
	animation_time += delta * 7.0
	update()


func _draw():
	# Ground shadow
	draw_colored_polygon(
		PoolVector2Array([
			Vector2(-9, 1),
			Vector2(0, -3),
			Vector2(9, 1),
			Vector2(0, 5)
		]),
		Color(0.10, 0.14, 0.17, 0.30)
	)

	var leg_swing = sin(animation_time) * 2.0
	var body_y = -18.0

	# Legs
	draw_line(
		Vector2(-2, body_y + 9),
		Vector2(-3 - leg_swing, -5),
		pants_color.darkened(0.12),
		3.5,
		true
	)

	draw_line(
		Vector2(2, body_y + 9),
		Vector2(3 + leg_swing, -5),
		pants_color,
		3.5,
		true
	)

	# Shoes
	draw_line(
		Vector2(-3 - leg_swing, -5),
		Vector2(-5 - leg_swing, -4),
		Color(0.12, 0.12, 0.14),
		3.0,
		true
	)

	draw_line(
		Vector2(3 + leg_swing, -5),
		Vector2(5 + leg_swing, -4),
		Color(0.12, 0.12, 0.14),
		3.0,
		true
	)

	# Arms
	draw_line(
		Vector2(-4, body_y + 2),
		Vector2(-6 + leg_swing * 0.4, body_y + 8),
		skin_color.darkened(0.05),
		3.5,
		true
	)

	draw_line(
		Vector2(4, body_y + 2),
		Vector2(6 - leg_swing * 0.4, body_y + 8),
		skin_color,
		3.5,
		true
	)

	# Torso
	draw_colored_polygon(
		PoolVector2Array([
			Vector2(-4, body_y - 1),
			Vector2(0, body_y - 3),
			Vector2(4, body_y - 1),
			Vector2(4, body_y + 9),
			Vector2(-4, body_y + 9)
		]),
		shirt_color.darkened(0.12)
	)

	# Front highlight
	draw_colored_polygon(
		PoolVector2Array([
			Vector2(-1, body_y - 2),
			Vector2(3, body_y - 1),
			Vector2(3, body_y + 8),
			Vector2(-1, body_y + 8)
		]),
		shirt_color.lightened(0.10)
	)

	# Neck
	draw_rect(
		Rect2(Vector2(-1.5, body_y - 5), Vector2(3, 5)),
		skin_color
	)

	# Head
	draw_circle(
		Vector2(0, body_y - 9),
		5.0,
		skin_color
	)

	# Hair
	draw_colored_polygon(
		PoolVector2Array([
			Vector2(-5, body_y - 9),
			Vector2(-4, body_y - 14),
			Vector2(0, body_y - 16),
			Vector2(4, body_y - 14),
			Vector2(5, body_y - 9),
			Vector2(2, body_y - 11),
			Vector2(-3, body_y - 11)
		]),
		hair_color
	)

	# Face detail
	draw_circle(
		Vector2(1.8, body_y - 8.5),
		0.65,
		Color(0.15, 0.12, 0.10)
	)
