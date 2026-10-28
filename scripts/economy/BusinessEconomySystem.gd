extends Reference

# ZekaCity - Business Economy System
# Godot 3.6

const CYCLE_INTERVAL = 60.0

const BUSINESS_DATA = {
	"grocery_store": {
		"revenue_per_worker": 80,
		"wage_per_worker": 30
	},
	"bakery": {
		"revenue_per_worker": 100,
		"wage_per_worker": 35
	},
	"restaurant": {
		"revenue_per_worker": 130,
		"wage_per_worker": 45
	},
	"office": {
		"revenue_per_worker": 160,
		"wage_per_worker": 60
	},
	"mineral_market": {
		"revenue_per_worker": 90,
		"wage_per_worker": 35
	},
	"shopping_mall": {
		"revenue_per_worker": 180,
		"wage_per_worker": 65
	},
	"factory": {
		"revenue_per_worker": 150,
		"wage_per_worker": 55
	}
}

var elapsed = 0.0


func process_economy(delta, world):
	if world == null:
		return

	elapsed += delta

	while elapsed >= CYCLE_INTERVAL:
		elapsed -= CYCLE_INTERVAL
		run_cycle(world)


func run_cycle(world):
	if world == null:
		return

	if world.citizen_system == null:
		return

	var citizens = world.citizen_system.citizens

	var total_revenue = 0
	var total_wages_paid = 0
	var total_owner_payout = 0
	var total_profit = 0

	for building_index in range(world.placed_buildings.size()):
		var building = world.placed_buildings[building_index]
		var building_id = str(building.get("id", ""))

		if not BUSINESS_DATA.has(building_id):
			continue

		var building_grid = building.get("grid", Vector2.ZERO)
		var workers = []

		# پیدا کردن کارکنان همین کسب‌وکار
		for citizen in citizens:
			if str(citizen.get("job_id", "")) != building_id:
				continue

			if citizen.get(
				"work_grid",
				Vector2(-999, -999)
			) != building_grid:
				continue

			workers.append(citizen)

		var data = BUSINESS_DATA[building_id]

		var revenue = workers.size() * int(
			data["revenue_per_worker"]
		)

		var wage_per_worker = int(
			data["wage_per_worker"]
		)

		var wages_due = workers.size() * wage_per_worker

		var balance = int(
			building.get("business_balance", 0)
		)

		var unpaid_wages = int(
			building.get("unpaid_wages", 0)
		)

		# اضافه کردن درآمد به حساب کسب‌وکار
		balance += revenue

		# پرداخت حقوق معوق و حقوق دوره جاری
		var total_due = unpaid_wages + wages_due
		var wages_paid = min(balance, total_due)

		balance -= wages_paid

		var paid_to_workers = _pay_workers(
			workers,
			wages_paid,
			total_due,
			wage_per_worker
		)

		# ثبت حقوق پرداخت‌نشده
		unpaid_wages = total_due - paid_to_workers

		# محاسبه سود پس از حقوق پرداخت‌شده
		var profit = revenue - paid_to_workers

		# پرداخت موجودی اضافه به مالک واقعی
		var owner_payout = balance

		if owner_payout > 0:
			var payout_success = _pay_business_owner(
				world,
				citizens,
				building,
				owner_payout
			)

			if payout_success:
				balance = 0
			else:
				owner_payout = 0

		# ذخیره اطلاعات مالی کسب‌وکار
		building["business_balance"] = balance
		building["unpaid_wages"] = unpaid_wages

		building["last_revenue"] = revenue
		building["last_wages"] = paid_to_workers
		building["last_profit"] = profit

		building["total_revenue"] = int(
			building.get("total_revenue", 0)
		) + revenue

		building["total_wages"] = int(
			building.get("total_wages", 0)
		) + paid_to_workers

		building["total_profit"] = int(
			building.get("total_profit", 0)
		) + profit

		world.placed_buildings[building_index] = building

		total_revenue += revenue
		total_wages_paid += paid_to_workers
		total_owner_payout += owner_payout
		total_profit += profit

		print(
			"BUSINESS ECONOMY | ", building_id,
			" | Workers: ", workers.size(),
			" | Revenue: $", revenue,
			" | Wages paid: $", paid_to_workers,
			" | Owner payout: $", owner_payout,
			" | Profit: $", profit,
			" | Balance: $", balance,
			" | Unpaid wages: $", unpaid_wages
		)

	print(
		"ECONOMY CYCLE COMPLETE",
		" | Revenue: $", total_revenue,
		" | Wages paid: $", total_wages_paid,
		" | Owner payouts: $", total_owner_payout,
		" | Net profit: $", total_profit
	)

	# ذخیره شهر پس از پایان چرخه
	if world.save_system != null:
		world.save_system.save_world(world)


func _pay_business_owner(world, citizens, building, amount):
	if amount <= 0:
		return true

	var owner_type = str(
		building.get("owner_type", "player")
	)

	var owner_id = str(
		building.get("owner_id", "player")
	)

	# پرداخت به بازیکن
	if owner_type == "player" or owner_id == "player":
		world.player_money = int(world.player_money) + amount

		print(
			"OWNER PAYOUT | Player received $",
			amount,
			" | Player money: $",
			world.player_money
		)

		return true

	# پرداخت به شهروند مالک
	for citizen_index in range(citizens.size()):
		var citizen = citizens[citizen_index]

		if str(citizen.get("id", "")) != owner_id:
			continue

		citizen["wallet"] = int(
			citizen.get("wallet", 0)
		) + amount

		citizens[citizen_index] = citizen

		print(
			"OWNER PAYOUT | Citizen ",
			owner_id,
			" received $",
			amount,
			" | Wallet: $",
			citizen["wallet"]
		)

		return true

	# مالک پیدا نشد؛ پول در حساب کسب‌وکار باقی می‌ماند.
	print(
		"OWNER PAYOUT FAILED | Owner not found: ",
		owner_id,
		" | Amount retained: $",
		amount
	)

	return false


func _pay_workers(workers, amount, total_due, wage_per_worker):
	if workers.empty() or amount <= 0 or total_due <= 0:
		return 0

	var remaining = amount
	var total_paid = 0

	for i in range(workers.size()):
		if remaining <= 0:
			break

		var citizen = workers[i]

		# سهم هر کارمند از حقوق
		var share = min(
			wage_per_worker,
			remaining
		)

		share = min(share, remaining)

		citizen["wallet"] = int(
			citizen.get("wallet", 0)
		) + share

		total_paid += share
		remaining -= share

	return total_paid
