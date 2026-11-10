extends Reference

const STORAGE_RESERVE = 50
# Keep a small buffer of intermediate goods for downstream workshops.
# Wood feeds sawmills; lumber feeds carpenters. These reserves prevent
# automatic market sales from starving the production chain.
const FORESTRY_RESERVES = {
	"wood": 20,
	"lumber": 10,
	"furniture": 0
}
const MAX_SALES_PER_SECOND = 2.0
const MAX_STOCK_PER_PRODUCT = 100
const SUPPLY_INTERVAL = 30.0
const SUPPLY_BATCH_SIZE = 5

# Forestry pricing follows the production chain:
# Wood wholesale = $12 (slightly above the existing $10 stone baseline).
# Lumber wholesale = 2 wood ($24) + $6 milling cost = $30.
# Furniture wholesale = 2 lumber ($60) + $20 assembly cost = $80.
# Retail prices apply the existing city-market markup: wood $18, lumber $42,
# furniture $112. Producers receive wholesale; the market earns the retail margin.
const PRODUCTS = {
	"stone": {
		"name": "Stone",
		"buy_price": 10,
		"sell_price": 15
	},
	"iron_ore": {
		"name": "Iron Ore",
		"buy_price": 25,
		"sell_price": 35
	},
	"wood": {
		"name": "Wood",
		"buy_price": 12,
		"sell_price": 18
	},
	"lumber": {
		"name": "Lumber",
		"buy_price": 30,
		"sell_price": 42
	},
	"furniture": {
		"name": "Furniture",
		"buy_price": 80,
		"sell_price": 112
	}
}

# موجودی قدیمی بازار برای سازگاری با SaveSystem حفظ شده است.
var stock = {
	"stone": 0,
	"iron_ore": 0,
	"wood": 0,
	"lumber": 0,
	"furniture": 0
}

# سهمیه فروش هر ماده مستقل است.
var sale_accumulators = {
	"stone": 0.0,
	"iron_ore": 0.0,
	"wood": 0.0,
	"lumber": 0.0,
	"furniture": 0.0
}

var supply_elapsed = 0.0


func get_products():
	return PRODUCTS.duplicate(true)


func get_stock(resource_id):
	return int(stock.get(resource_id, 0))


func get_price(resource_id):
	if not PRODUCTS.has(resource_id):
		return 0

	return int(PRODUCTS[resource_id]["buy_price"])


func get_sell_price(resource_id):
	if not PRODUCTS.has(resource_id):
		return 0

	return int(PRODUCTS[resource_id]["sell_price"])


func can_supply(resource_id, amount):
	if not PRODUCTS.has(resource_id):
		return false

	return get_stock(resource_id) >= int(amount)


# فروش خودکار از موجودی ResourceManager
func process_automatic_sales(delta, world):
	if world == null:
		return

	if world.resource_manager == null:
		return

	if delta <= 0:
		return

	var market_index = _find_mineral_market(world)

	# بدون بازار معدنی هیچ فروشی انجام نمی‌شود.
	if market_index == -1:
		return

	for resource_id in PRODUCTS.keys():
		_process_resource_sale(resource_id, delta, world, market_index)


func _process_resource_sale(resource_id, delta, world, market_index):
	if not PRODUCTS.has(resource_id):
		return

	var current_amount = world.resource_manager.get_amount(resource_id)
	var reserve = _get_resource_reserve(resource_id)
	var available = max(0, current_amount - reserve)

	# موجودی به حد ذخیره رسیده؛ سهمیه قبلی پاک شود.
	if available <= 0:
		sale_accumulators[resource_id] = 0.0
		return

	sale_accumulators[resource_id] = min(5.0, sale_accumulators[resource_id] + delta * MAX_SALES_PER_SECOND)

	var amount_due = int(floor(sale_accumulators[resource_id]))
	if amount_due <= 0:
		return

	var amount_to_sell = min(amount_due, available)

	if amount_to_sell <= 0:
		return

	var producer_index = _get_forestry_producer_index(world, resource_id)
	var forestry_product = producer_index >= 0
	var unit_price = get_price(resource_id) if forestry_product else get_sell_price(resource_id)

	if forestry_product:
		var market_room = MAX_STOCK_PER_PRODUCT - get_stock(resource_id)
		amount_to_sell = min(amount_to_sell, max(0, market_room))
		if world.city_treasury == null:
			return
		var affordable = int(floor(float(world.city_treasury.get_available_money()) / float(unit_price)))
		amount_to_sell = min(amount_to_sell, affordable)

	if amount_to_sell <= 0:
		return

	var total_revenue = amount_to_sell * unit_price
	if not world.resource_manager.remove_resource(resource_id, amount_to_sell):
		return

	if forestry_product:
		if not world.city_treasury.spend(total_revenue):
			world.resource_manager.add_resource(resource_id, amount_to_sell)
			return
		stock[resource_id] = get_stock(resource_id) + amount_to_sell
		_add_business_revenue(world, producer_index, total_revenue)
	else:
		_add_business_revenue(world, market_index, total_revenue)

	# سهمیه فقط به اندازه فروش موفق مصرف می‌شود.
	sale_accumulators[resource_id] -= amount_to_sell

	# وقتی موجودی به حد ذخیرهٔ تعریف‌شده رسید، سهمیهٔ فروش پاک شود.
	if world.resource_manager.get_amount(resource_id) <= reserve:
		sale_accumulators[resource_id] = 0.0


func _get_resource_reserve(resource_id):
	if resource_id in ["stone", "iron_ore"]:
		return STORAGE_RESERVE

	return int(FORESTRY_RESERVES.get(resource_id, 0))


func _get_forestry_producer_index(world, resource_id):
	var producer_id = {
		"wood": "woodcutter",
		"lumber": "sawmill",
		"furniture": "carpenter"
	}.get(resource_id, "")
	if producer_id == "":
		return -1

	# Only staffed producers receive wholesale payment. When several
	# workshops produce the same resource, send the next sale to the
	# producer with the smallest current balance to distribute income.
	var selected_index = -1
	var lowest_balance = 0

	for i in range(world.placed_buildings.size()):
		var building = world.placed_buildings[i]
		if str(building.get("id", "")) != producer_id:
			continue
		if not _building_has_worker(world, building):
			continue

		var balance = int(building.get("business_balance", 0))
		if selected_index == -1 or balance < lowest_balance:
			selected_index = i
			lowest_balance = balance

	return selected_index


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


func _find_mineral_market(world):
	if not world.has_method("get"):
		return -1

	if world.get("placed_buildings") == null:
		return -1

	for i in range(world.placed_buildings.size()):
		var building = world.placed_buildings[i]

		if str(building.get("id", "")) == "mineral_market":
			return i

	return -1


func _add_business_revenue(world, market_index, revenue):
	if market_index < 0:
		return

	if market_index >= world.placed_buildings.size():
		return

	var building = world.placed_buildings[market_index]

	var current_balance = int(building.get("business_balance", 0))
	var current_total = int(building.get("total_revenue", 0))

	building["business_balance"] = current_balance + revenue
	building["last_revenue"] = revenue
	building["total_revenue"] = current_total + revenue

	world.placed_buildings[market_index] = building


# Transfer from the market's saved stock to a citizen.
func sell_to_customer(resource_id, amount, wallet, building):
	if not PRODUCTS.has(resource_id):
		return {
			"success": false,
			"error": "UNKNOWN_PRODUCT"
		}

	if typeof(building) != TYPE_DICTIONARY:
		return {
			"success": false,
			"error": "INVALID_MARKET"
		}

	var quantity = int(amount)
	if quantity <= 0:
		return {
			"success": false,
			"error": "INVALID_AMOUNT"
		}

	var available = get_stock(resource_id)
	if available < quantity:
		return {
			"success": false,
			"error": "OUT_OF_STOCK"
		}

	var total_cost = get_sell_price(resource_id) * quantity
	if int(wallet) < total_cost:
		return {
			"success": false,
			"error": "INSUFFICIENT_FUNDS"
		}

	stock[resource_id] = available - quantity

	building["business_balance"] = int(
		building.get("business_balance", 0)
	) + total_cost
	building["last_revenue"] = total_cost
	building["total_revenue"] = int(
		building.get("total_revenue", 0)
	) + total_cost

	return {
		"success": true,
		"cost": total_cost,
		"remaining_money": int(wallet) - total_cost
	}


# Replenish a small batch at a fixed interval so the market does not
# instantly consume all municipal resources or treasury funds.
func process_market_supply(delta, world):
	if world == null or delta <= 0:
		return

	if world.resource_manager == null or world.city_treasury == null:
		return

	if _find_mineral_market(world) == -1:
		return

	supply_elapsed += delta
	if supply_elapsed < SUPPLY_INTERVAL:
		return

	supply_elapsed = 0.0

	for resource_id in PRODUCTS.keys():
		if resource_id in ["wood", "lumber", "furniture"]:
			continue
		receive_from_municipal_storage(
			world.resource_manager,
			resource_id,
			SUPPLY_BATCH_SIZE,
			world.city_treasury
		)


# Purchase stock from municipal storage using the market's working
# capital policy: the municipality pays the configured wholesale price.
func receive_from_municipal_storage(resource_manager, resource_id, amount, treasury):
	if not PRODUCTS.has(resource_id):
		return {
			"success": false,
			"error": "UNKNOWN_PRODUCT"
		}

	if resource_manager == null or treasury == null:
		return {
			"success": false,
			"error": "INVALID_ECONOMY_REFERENCE"
		}

	var quantity = int(amount)
	if quantity <= 0:
		return {
			"success": false,
			"error": "INVALID_AMOUNT"
		}

	var current_stock = get_stock(resource_id)
	var accepted_quantity = min(
		quantity,
		min(
			MAX_STOCK_PER_PRODUCT - current_stock,
			resource_manager.get_amount(resource_id)
		)
	)

	if accepted_quantity <= 0:
		return {
			"success": false,
			"error": "NO_AVAILABLE_SUPPLY_OR_CAPACITY"
		}

	var unit_price = get_price(resource_id)
	var total_cost = unit_price * accepted_quantity

	if not treasury.can_afford(total_cost):
		accepted_quantity = int(
			floor(float(treasury.get_available_money()) / float(unit_price))
		)
		accepted_quantity = min(
			accepted_quantity,
			min(
				quantity,
				min(
					MAX_STOCK_PER_PRODUCT - current_stock,
					resource_manager.get_amount(resource_id)
				)
			)
		)
		total_cost = unit_price * accepted_quantity

	if accepted_quantity <= 0:
		return {
			"success": false,
			"error": "INSUFFICIENT_TREASURY_FUNDS"
		}

	# Spend first, then remove the matching stock. If removal fails,
	# refund the treasury so the transfer remains atomic.
	if not treasury.spend(total_cost):
		return {
			"success": false,
			"error": "TREASURY_PAYMENT_FAILED"
		}

	if not resource_manager.remove_resource(resource_id, accepted_quantity):
		treasury.add_money(total_cost)
		return {
			"success": false,
			"error": "RESOURCE_TRANSFER_FAILED"
		}

	stock[resource_id] = current_stock + accepted_quantity

	return {
		"success": true,
		"quantity": accepted_quantity,
		"cost": total_cost,
		"remaining_stock": stock[resource_id]
	}


func restore_stock(data):
	if typeof(data) != TYPE_DICTIONARY:
		return

	for resource_id in stock.keys():
		stock[resource_id] = int(data.get(resource_id, 0))


func get_stock_data():
	return stock.duplicate(true)
