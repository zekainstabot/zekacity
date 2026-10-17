extends Reference

# ZekaCity - MineSystem.gd
# Godot 3.6
# تولید منابع با رعایت ظرفیت انبار

var mines = {}
var production_interval = 5.0
var iron_refill_cost = 1000


func build_mine(mountain_id, resource_id, reserve = 0):
	if mines.has(mountain_id):
		return false

	if resource_id != "stone" and resource_id != "iron_ore":
		return false

	var initial_reserve = -1

	if resource_id == "iron_ore":
		initial_reserve = max(0, int(reserve))

	mines[mountain_id] = {
		"resource_id": resource_id,
		"active": initial_reserve != 0 if resource_id == "iron_ore" else true,
		"remaining": initial_reserve,
		"initial_reserve": initial_reserve,
		"extracted": 0,
		"elapsed": 0.0
	}

	return true


func has_mine(mountain_id):
	return mines.has(mountain_id)


func get_mine_count():
	return mines.size()


func get_mine_resource(mountain_id):
	if not mines.has(mountain_id):
		return ""

	return str(mines[mountain_id]["resource_id"])


func is_mine_active(mountain_id):
	if not mines.has(mountain_id):
		return false

	return bool(mines[mountain_id]["active"])


func get_remaining(mountain_id):
	if not mines.has(mountain_id):
		return 0

	if str(mines[mountain_id]["resource_id"]) == "stone":
		return -1

	return int(mines[mountain_id]["remaining"])


func get_extracted(mountain_id):
	if not mines.has(mountain_id):
		return 0

	return int(mines[mountain_id]["extracted"])


func advance(delta, resource_manager):
	if resource_manager == null:
		return

	for mountain_id in mines.keys():
		var mine = mines[mountain_id]

		if not mine["active"]:
			continue

		mine["elapsed"] += delta

		while mine["elapsed"] >= production_interval:
			if not mine["active"]:
				break

			var resource_id = str(mine["resource_id"])

			if resource_id == "iron_ore":
				if int(mine["remaining"]) <= 0:
					mine["active"] = false
					break

			# اگر انبار پر باشد، تولید منتظر می‌ماند.
			# زمان تولید و ذخیره آهن تا زمان ذخیره موفق مصرف نمی‌شوند.
			if not resource_manager.add_resource(resource_id, 1):
				break

			mine["elapsed"] -= production_interval
			mine["extracted"] += 1

			if resource_id == "iron_ore":
				mine["remaining"] -= 1

				if int(mine["remaining"]) <= 0:
					mine["active"] = false
					break

		mines[mountain_id] = mine


func refill_iron(mountain_id, city_treasury):
	if not mines.has(mountain_id):
		return false

	var mine = mines[mountain_id]

	if str(mine["resource_id"]) != "iron_ore":
		return false

	if city_treasury == null:
		return false

	if not city_treasury.can_afford(iron_refill_cost):
		return false

	if not city_treasury.spend(iron_refill_cost):
		return false

	mine["remaining"] = int(mine["initial_reserve"])
	mine["active"] = int(mine["initial_reserve"]) > 0
	mine["elapsed"] = 0.0

	mines[mountain_id] = mine

	return true


func set_mine_active(mountain_id, active):
	if not mines.has(mountain_id):
		return false

	var mine = mines[mountain_id]

	if str(mine["resource_id"]) == "iron_ore":
		if int(mine["remaining"]) <= 0 and active:
			return false

	mine["active"] = active
	mines[mountain_id] = mine

	return true
