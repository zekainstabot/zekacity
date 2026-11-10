extends Reference

const STORAGE_RESERVE = 50
const MAX_SALES_PER_SECOND = 2.0

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
	}
}

# موجودی قدیمی بازار برای سازگاری با SaveSystem حفظ شده است.
var stock = {
	"stone": 0,
	"iron_ore": 0
}

# سهمیه فروش هر ماده مستقل است.
var sale_accumulators = {
	"stone": 0.0,
	"iron_ore": 0.0
}


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

	_process_resource_sale("stone", delta, world, market_index)
	_process_resource_sale("iron_ore", delta, world, market_index)


func _process_resource_sale(resource_id, delta, world, market_index):
	if not PRODUCTS.has(resource_id):
		return

	var current_amount = world.resource_manager.get_amount(resource_id)
	var available = max(0, current_amount - STORAGE_RESERVE)

	# موجودی به حد ذخیره رسیده؛ سهمیه قبلی پاک شود.
	if available <= 0:
		sale_accumulators[resource_id] = 0.0
		return

	sale_accumulators[resource_id] += delta * MAX_SALES_PER_SECOND

	var amount_due = int(floor(sale_accumulators[resource_id]))
	if amount_due <= 0:
		return

	var amount_to_sell = min(amount_due, available)

	if amount_to_sell <= 0:
		return

	var sold = world.resource_manager.remove_resource(
		resource_id,
		amount_to_sell
	)

	if not sold:
		return

	# سهمیه فقط به اندازه فروش موفق مصرف می‌شود.
	sale_accumulators[resource_id] -= amount_to_sell

	var revenue = amount_to_sell * get_sell_price(resource_id)

	_add_business_revenue(
		world,
		market_index,
		revenue
	)

	# اگر موجودی به ذخیره ۵۰ رسید، سهمیه باقی‌مانده حذف شود.
	if world.resource_manager.get_amount(resource_id) <= STORAGE_RESERVE:
		sale_accumulators[resource_id] = 0.0


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


# Municipal-to-market supply remains disabled until its pricing and
# inventory-transfer rules are exposed in the market UI.
func receive_from_municipal_storage(resource_manager, resource_id, amount, treasury):
	return {
		"success": false,
		"error": "SUPPLY_TRANSFER_NOT_CONFIGURED"
	}


func restore_stock(data):
	if typeof(data) != TYPE_DICTIONARY:
		return

	for resource_id in stock.keys():
		stock[resource_id] = int(data.get(resource_id, 0))


func get_stock_data():
	return stock.duplicate(true)
