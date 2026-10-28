extends Reference

# ZekaCity - Business Economy System
# Godot 3.6
# Final payroll interval: 10 minutes

const PAYROLL_INTERVAL = 600.0

const BUSINESS_DATA = {
	"grocery_store": {"wage_per_worker": 30},
	"bakery": {"wage_per_worker": 35},
	"restaurant": {"wage_per_worker": 45},
	"office": {"wage_per_worker": 60},
	"mineral_market": {"wage_per_worker": 35},
	"shopping_mall": {"wage_per_worker": 65},
	"factory": {"wage_per_worker": 55}
}

# برای آزمایش می‌توان این مقدار را موقتاً به 60 تغییر داد.
var payroll_interval = PAYROLL_INTERVAL
var elapsed = 0.0


func process_economy(delta, world):
	if world == null:
		return

	elapsed += delta

	while elapsed >= payroll_interval:
		elapsed -= payroll_interval
		run_payroll(world)


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

	if world.save_system != null:
		world.save_system.save_world(world)


func _pay_workers(workers, amount, wage_per_worker):
	if workers.empty() or amount <= 0:
		return 0

	var remaining = amount
	var total_paid = 0

	for i in range(workers.size()):
		if remaining <= 0:
			break

		var share = min(wage_per_worker, remaining)
		var citizen = workers[i]

		citizen["wallet"] = int(
			citizen.get("wallet", 0)
		) + share

		workers[i] = citizen
		total_paid += share
		remaining -= share

	return total_paid
