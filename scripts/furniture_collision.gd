extends TileMapLayer

## Для каждого атласного тайла тайлсета строит коллизионные полигоны
## по непрозрачным пикселям текстуры через BitMap.opaque_to_polygons.
## Сетка коллизии совпадает с пиксельной сеткой; прозрачные пиксели игнорируются.
##
## Физический слой 0 назначаем на bit 8 (furniture). Маска 0 — на объектах, что
## имеют бит 8 в collision_mask (персонажи), срабатывает блокировка.
## Пули в своих масках бита 8 не имеют → пролетают сквозь.

const POLY_EPSILON := 1.0
const ALPHA_THRESHOLD := 0.1


func _ready() -> void:
	if tile_set == null:
		return
	_ensure_physics_layer()
	var tile_size: Vector2i = tile_set.tile_size
	var half := Vector2(tile_size) * 0.5

	for i in tile_set.get_source_count():
		var source := tile_set.get_source(tile_set.get_source_id(i))
		if not (source is TileSetAtlasSource):
			continue
		var atlas := source as TileSetAtlasSource
		if atlas.texture == null:
			continue
		var image := atlas.texture.get_image()
		if image == null:
			continue

		for t in atlas.get_tiles_count():
			var coords := atlas.get_tile_id(t)
			var rect := Rect2i(coords * tile_size, tile_size)
			if rect.end.x > image.get_width() or rect.end.y > image.get_height():
				continue
			var sub := image.get_region(rect)
			var bm := BitMap.new()
			bm.create_from_image_alpha(sub, ALPHA_THRESHOLD)
			var polys := bm.opaque_to_polygons(Rect2(Vector2.ZERO, Vector2(tile_size)), POLY_EPSILON)

			for a in atlas.get_alternative_tiles_count(coords):
				var alt := atlas.get_alternative_tile_id(coords, a)
				var data := atlas.get_tile_data(coords, alt)
				if data == null:
					continue
				# Очистим существующие полигоны, чтобы не накапливать после hot-reload
				while data.get_collision_polygons_count(0) > 0:
					data.remove_collision_polygon(0, 0)
				for pi in polys.size():
					var poly: PackedVector2Array = polys[pi]
					var shifted := PackedVector2Array()
					shifted.resize(poly.size())
					for vi in poly.size():
						shifted[vi] = poly[vi] - half
					data.add_collision_polygon(0)
					data.set_collision_polygon_points(0, pi, shifted)


func _ensure_physics_layer() -> void:
	if tile_set.get_physics_layers_count() == 0:
		tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 128)
	tile_set.set_physics_layer_collision_mask(0, 0)
