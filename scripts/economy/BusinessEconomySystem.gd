extends Reference

# ZekaCity - Business Economy System
# Godot 3.6

const PAYROLL_INTERVAL = 600.0

const BUSINESS_DATA = {
	"grocery_store": {"wage_per_worker": 30},
	"bakery": {"wage_per_worker": 35},
	"restaurant": {"wage_per_worker": 45},
	"office": {"wage_per_worker": 60},
	"mineral_market": {"wage_per_worker": 35},
	"shopping_mall": {"wage_per_worker": 65},
	"factory": {"wage_per_worker": 55},
	"woodcutter": {"wage_per_worker": 32},
	"sawmill": {"wage_per_worker": 42},
	"carpenter": {"wage_per_worker": 48}
}

var payroll_interval = PAYROLL_INTERVAL
var elapsed = 0.0
var payroll_rotation = 0
var production_interval = 30.0
var production_elapsed = 0.0


func process_economy(delta, world):
	if world == null:
		return

	elapsed += delta

	while elapsed >= payroll_interval:
		elapsed -= payroll_interval
		run_payroll(world)

	production_elapsed += delta
	while production_elapsed >= production_interval:
		production_elapsed -= production_interval
		process_wood_industry(world)


func run_payroll(world):
	if world == null or world.citizen_system == null:
		return

	var citizens = world.citizen_system.citizens
	var total_wages_paid = 0
	var total_unpaid_wages = 0

	for building_index in range(world.placed_buildings.size()):
		var building = world.placed_buildings[building_index]
		var building_id = str(building.get("id", ""))

		if not BUSINESS_DATA.has(building_id):
			continue

		var building_grid = building.get("grid", Vector2.ZERO)
		var workers = []

		for citizen in citizens:
			if str(citizen.get("job_id", "")) != building_id:
				continue

			if citizen.get(
				"work_grid",
				Vector2(-999, -999)
			) != building_grid:
				continue

			workers.append(citizen)

		var wage_per_worker = int(
			BUSINESS_DATA[building_id]["wage_per_worker"]
		)

		var wages_due = workers.size() * wage_per_worker
		var unpaid_before = int(
			building.get("unpaid_wages", 0)
		)

		var total_due = unpaid_before + wages_due
		var balance = int(
			building.get("business_balance", 0)
		)

		var amount_to_pay = min(balance, total_due)

		var paid = _pay_workers(
			workers,
			amount_to_pay,
			wage_per_worker
		)

		balance -= paid
		var unpaid_after = total_due - paid

		building["business_balance"] = balance
		building["unpaid_wages"] = unpaid_after
		building["last_wages"] = paid
		building["total_wages"] = int(
			building.get("total_wages", 0)
		) + paid

		world.placed_buildings[building_index] = building

		total_wages_paid += paid
		total_unpaid_wages += unpaid_after

		print(
			"PAYROLL | ", building_id,
			" | Workers: ", workers.size(),
			" | Due: $", total_due,
			" | Paid: $", paid,
			" | Unpaid: $", unpaid_after,
			" | Business balance: $", balance
		)

	print(
		"PAYROLL COMPLETE",
		" | Total paid: $", total_wages_paid,
		" | Total unpaid: $", total_unpaid_wages
	)

	# Transfer remaining business money to the city treasury.
	_transfer_business_surplus(world)

	if world.save_system != null:
		world.save_system.save_world(world)


func _transfer_business_surplus(world):
	if world.city_treasury == null:
		return

	var total_transferred = 0

	for building_index in range(world.placed_buildings.size()):
		var building = world.placed_buildings[building_index]
		var building_id = str(building.get("id", ""))

		if not BUSINESS_DATA.has(building_id):
			continue

		var balance = int(
			building.get("business_balance", 0)
		)

		if balance <= 0:
			continue

		var accepted = world.city_treasury.add_money(balance)

		if accepted <= 0:
			continue

		building["business_balance"] = balance - accepted
		building["total_profit"] = int(
			building.get("total_profit", 0)
		) + accepted

		world.placed_buildings[building_index] = building
		total_transferred += accepted

		print(
			"BUSINESS SURPLUS TRANSFER | ",
			building_id,
			" | Transferred: $", accepted,
			" | Remaining: $",
			building["business_balance"]
		)

	print(
		"BUSINESS SURPLUS TRANSFER COMPLETE",
		" | Total transferred: $", total_transferred,
		" | Treasury: $", world.city_treasury.get_balance()
	)


func _pay_workers(workers, amount, wage_per_worker):
	if workers.empty() or amount <= 0:
		return 0

	var total_amount = int(amount)
	var base_share = int(floor(
		float(total_amount) / float(workers.size())
	))
	var remainder = total_amount - base_share * workers.size()
	var start_index = payroll_rotation % workers.size()

	# Split both current wages and accumulated arrears evenly. Rotate
	# the remainder so the same citizen is not always paid first.
	for offset in range(workers.size()):
		var worker_index = (start_index + offset) % workers.size()
		var share = base_share

		if offset < remainder:
			share += 1

		if share <= 0:
			continue

		var citizen = workers[worker_index]
		citizen["wallet"] = int(
			citizen.get("wallet", 0)
		) + share
		workers[worker_index] = citizen

	payroll_rotation = (start_index + 1) % workers.size()
	return total_amount


# --------------------------------------------------
# FORESTRY PRODUCTION CHAIN
# Woodcutter -> wood -> sawmill -> lumber -> carpenter -> furniture
# Every 30 seconds, each staffed building runs one production cycle.
# --------------------------------------------------

func process_wood_industry(world):
	if world == null or world.resource_manager == null:
		return

	var forest = world.get_node_or_null("../ForestSystem")
	if forest == null:
		return

	for building_index in range(world.placed_buildings.size()):
		var building = world.placed_buildings[building_index]
		var building_id = str(building.get("id", ""))
		if building_id not in ["woodcutter", "sawmill", "carpenter"]:
			continue

		if not _building_has_worker(world, building):
			continue

		var produced = false

		match building_id:
			"woodcutter":
				# Reserve storage first; never remove a tree if logs cannot fit.
				var free_capacity = world.storage_system.get_free_capacity(world.resource_manager) if world.storage_system != null else 999999
				if free_capacity >= 2 and world.resource_manager.add_resource("wood", 2):
					if forest.harvest_near(building.get("grid", Vector2.ZERO), 6):
						produced = true
					else:
						world.resource_manager.remove_resource("wood", 2)
			"sawmill":
				if world.resource_manager.get_amount("wood") >= 2:
					if world.resource_manager.remove_resource("wood", 2):
						if world.resource_manager.add_resource("lumber", 1):
							produced = true
						else:
							world.resource_manager.add_resource("wood", 2)
			"carpenter":
				if world.resource_manager.get_amount("lumber") >= 2:
					if world.resource_manager.remove_resource("lumber", 2):
						if world.resource_manager.add_resource("furniture", 1):
							produced = true
						else:
							world.resource_manager.add_resource("lumber", 2)

		if produced:
			building["last_revenue"] = 0
			world.placed_buildings[building_index] = building
			print("WOOD INDUSTRY PRODUCTION | ", building_id, " | Inventory: ", world.resource_manager.get_all_amounts())


func _building_has_worker(world, building):
	if world == null or world.citizen_system == null:
		return false

	var building_id = str(building.get("id", ""))
	var building_grid = building.get("grid", Vector2.ZERO)

	for citizen in world.citizen_system.citizens:
		if str(citizen.get("job_id", "")) != building_id:
			continue
		if citizen.get("work_grid", Vector2(-999, -999)) == building_grid:
			return true
	return false
