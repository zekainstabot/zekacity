extends Reference

# ZekaCity - BuildingArtPrompt.gd
# Godot 3.6
#
# Produces a consistent English image-generation brief for any building.
# Usage:
# var art_prompt = preload("res://scripts/buildings/BuildingArtPrompt.gd").new()
# print(art_prompt.get_prompt("small_house", building_footprints))
#
# Copy the returned text into an image generator. The output is designed
# for BuildingVisual.gd: transparent PNG, centered bottom anchor, no tile/base.

const BuildingData = preload("res://scripts/BuildingData.gd")

const STYLE_GUIDE = "Create a polished 2.5D isometric city-builder game building asset for ZekaCity. Match one coherent stylized-realistic miniature architecture art direction: clean readable geometry, carefully modeled materials, subtle hand-painted texture, warm natural daylight, soft ambient occlusion, crisp edges, believable architectural proportions. CAMERA LOCK: use the exact same orthographic isometric three-quarter camera for every asset, same azimuth and elevation, always show the front and right side, keep every vertical wall edge perfectly vertical, keep the building upright (never tilted, rolled, skewed, or viewed from above at a different angle), no perspective distortion. Keep the building aligned to the isometric grid axes; do not rotate individual buildings."

const OUTPUT_GUIDE = "OUTPUT CONTRACT: one building only, isolated on a fully transparent alpha background, PNG, square 1024x1024 canvas. Center the building horizontally; place the lowest ground-contact pixel on the same bottom-center anchor line for every asset (x=512, y=920). Keep the complete structure upright and fully visible. The visible building should occupy a consistent proportion of the canvas; do not add artificial empty margins inside the silhouette. NO ground tile, diamond tile, grass platform, terrain base, road, pavement, shadow plane, scenery, trees, shrubs, flowers, people, vehicles, neighboring buildings, text, labels, watermark, UI, frame, or border. Do not crop roofs, chimneys, towers, or foundations. Preserve the same camera angle and lighting direction for every building. Fit the architecture to its stated grid footprint: its base must be centered and have a clear, stable contact edge, with no diagonal drift or sideways lean. Strong readable silhouette and details at small game-camera size."

const BUILDING_DESCRIPTIONS = {
	"small_house": "A modest starter cottage for a few residents, compact one-story home, simple pitched roof, small porch, welcoming windows, affordable materials.",
	"normal_house": "A comfortable suburban family home, two-story massing, pitched roof, front entrance, balcony or porch, garden-free compact footprint.",
	"low_apartment": "A low-rise residential apartment block, three to four floors, repeated balconies and windows, practical urban facade.",
	"high_apartment": "A modern mid/high-rise apartment building, clearly taller vertical silhouette, many residential windows and balconies, contemporary facade.",
	"residential_tower": "A premium tall residential tower, elegant modern architecture, stacked balconies, glass and stone facade, distinctive rooftop crown.",
	"grocery_store": "A neighborhood grocery store, broad shopfront windows, visible entrance, modest commercial signage shapes without readable letters, delivery-side door.",
	"bakery": "A small artisan bakery, warm inviting storefront, display windows, subtle oven chimney or ventilation, brick and timber details.",
	"restaurant": "A standalone neighborhood restaurant, welcoming entrance, large dining windows, tasteful canopy, outdoor-facing facade details.",
	"office": "A compact modern office building, multiple floors, regular glass window grid, professional facade, flat roof.",
	"shopping_mall": "A large multi-wing shopping mall, broad glass storefront facade, multiple entrances, modern roofline and clear retail architecture.",
	"factory": "A medium industrial factory, large production hall, sawtooth or pitched industrial roof, loading doors, restrained smokestack or ventilation equipment.",
	"mineral_market": "A small specialized mineral and ore exchange market, sturdy stone-and-timber trading hall, display bays and industrial scales.",
	"woodcutter": "A forestry woodcutter's depot, small timber shed, stacked cut logs, chopping/work area integrated into the building footprint, rugged woodland-industry character.",
	"sawmill": "A working sawmill, long industrial timber-processing hall, visible sawmill machinery hints, log intake bay, stacked lumber racks attached to the structure.",
	"carpenter": "A carpentry workshop, craftsman's timber building, broad workshop doors, organized lumber and finished furniture details, small dust-extraction vent.",
	"water_tower": "A municipal water tower, tall elevated water tank on strong support legs, access ladder and pipes, compact utility footprint.",
	"power_station": "A small city power station, industrial turbine hall, transformer equipment, insulators and controlled utility details, no dramatic smoke.",
	"sewage_plant": "A compact wastewater treatment facility, low industrial buildings, visible circular treatment tanks and connected pipes, clean engineered appearance.",
	"waste_facility": "A municipal waste sorting and recycling facility, industrial shed, loading bay, sorting conveyor hints and recycling equipment, no piles of trash.",
	"school": "A friendly elementary school, two-story institutional building, broad windows, welcoming entrance and a small clock or school-bell feature.",
	"university": "A substantial university academic building, multi-wing campus architecture, grand entrance, repeated windows, refined stone and brick details.",
	"clinic": "A small neighborhood medical clinic, clean low-rise building, clear entrance canopy, large windows, subtle medical cross symbol only if legible as a simple icon.",
	"hospital": "A modern multi-story hospital, broad clinical wings, ambulance entrance canopy, regular windows, rooftop mechanical details.",
	"police_station": "A civic police station, secure public entrance, official but understated architecture, garage bay and a small badge-shaped emblem without readable text.",
	"fire_station": "A fire station, recognizable wide vehicle bay doors, practical two-story station building, watch/alert tower detail, no fire trucks.",
	"city_hall": "A dignified central city hall, civic neoclassical or modern civic architecture, broad steps, columns or a clear public entrance, distinctive central roof feature.",
	"small_park": "A compact landscaped neighborhood park asset, a small pavilion or gazebo, benches and a few carefully grouped shrubs; keep it as one self-contained park asset.",
	"playground": "A compact children's playground asset, colorful climbing frame, slide and swings arranged as one coherent small facility, no people.",
	"sports_center": "A medium indoor sports center, broad gymnasium volume, high roof, repeated clerestory windows and a clear public entrance.",
	"cultural_center": "A modern cultural center, expressive civic architecture, gallery windows, auditorium volume and a distinctive but practical roofline.",
	"small_warehouse": "A small storage warehouse, simple industrial shed, one loading door and corrugated or panel-clad walls.",
	"medium_warehouse": "A medium logistics warehouse, broad rectangular storage hall, two loading bays, practical industrial roof.",
	"large_warehouse": "A large distribution warehouse, tall industrial hall, several loading bays and a clear repeated structural rhythm.",
	"huge_warehouse": "A very large logistics center, expansive warehouse volume, multiple loading docks and a high-capacity industrial silhouette."
}


func get_prompt(building_id, footprint_service):
	if not BuildingData.BUILDINGS.has(building_id):
		return ""

	var building = BuildingData.BUILDINGS[building_id]
	var dimensions = Vector2.ONE
	if footprint_service != null:
		dimensions = footprint_service.get_footprint(building_id)
	else:
		var raw_dimensions = BuildingData.BUILDING_LAYOUTS.get(
			building_id,
			[1, 1]
		)
		dimensions = Vector2(
			int(raw_dimensions[0]),
			int(raw_dimensions[1])
		)

	var description = BUILDING_DESCRIPTIONS.get(
		building_id,
		"A " + str(building.get("name", building_id)) + " building with a clear, recognizable architectural silhouette."
	)

	var size_line = "Grid footprint: %d tiles wide by %d tiles deep." % [
		int(dimensions.x),
		int(dimensions.y)
	]

	var identity_line = "Building: %s. Category: %s. City development stage: %s." % [
		str(building.get("name", building_id)),
		str(building.get("category", "Building")),
		str(building.get("stage", 1))
	]

	return STYLE_GUIDE + "\n\n" + identity_line + "\n" + size_line + "\nDesign brief: " + description + "\n\n" + OUTPUT_GUIDE


func get_all_prompts(footprint_service):
	var prompts = {}
	for building_id in BuildingData.BUILDINGS.keys():
		if building_id == "road":
			continue
		prompts[building_id] = get_prompt(building_id, footprint_service)
	return prompts


func get_supported_building_ids():
	var result = []
	for building_id in BuildingData.BUILDINGS.keys():
		if building_id != "road":
			result.append(building_id)
	result.sort()
	return result
