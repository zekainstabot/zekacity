extends Node2D

# A mountain is its own CanvasItem so its ground depth can interleave
# correctly with individual trees and building visuals.
var mountain_texture = null
var mine_texture = null
var mine_built = false
var pickaxe_position = Vector2.ZERO
var draw_size = Vector2.ZERO
var mine_position = Vector2.ZERO


func _draw():
	if mountain_texture != null:
		draw_texture_rect(
			mountain_texture,
			Rect2(Vector2(-draw_size.x / 2.0, -draw_size.y), draw_size),
			false
		)

	if mine_built:
		if mine_texture != null:
			var texture_size = mine_texture.get_size()
			if texture_size.x > 0 and texture_size.y > 0:
				var target_size = Vector2(80, 72)
				var scale_factor = min(
					target_size.x / texture_size.x,
					target_size.y / texture_size.y
				)
				var size = texture_size * scale_factor
				draw_texture_rect(
					mine_texture,
					Rect2(mine_position - Vector2(size.x / 2.0, size.y), size),
					false
				)
	else:
		draw_line(
			pickaxe_position + Vector2(-5, 7),
			pickaxe_position + Vector2(6, -7),
			Color(0.40, 0.23, 0.12),
			4.0
		)
		draw_line(
			pickaxe_position + Vector2(-10, -6),
			pickaxe_position + Vector2(9, -9),
			Color(0.75, 0.78, 0.82),
			5.0
		)
