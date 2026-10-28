
extends Reference

# ZekaCity - MineralMarketSystem.gd
# Godot 3.6
# مدیریت فروشگاه مصالح معدنی شهرداری

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

var stock = {
	"stone": 0,
	"iron_ore": 0
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

	if amount <= 0:
		return false

	return get_stock(resource_id) >= int(amount)



func receive_from_municipal_storage(
	resource_id,
	amount,
	resource_manager,
	city_treasury
):
	if not PRODUCTS.has(resource_id):
		return {
			"success": false,
			"error": "INVALID_PRODUCT"
		}

	amount = int(amount)

	if amount <= 0:
		return {
			"success": false,
			"error": "INVALID_AMOUNT"
		}

	if resource_manager == null or city_treasury == null:
		return {
			"success": false,
			"error": "SYSTEM_UNAVAILABLE"
		}

	if resource_manager.get_amount(resource_id) < amount:
		return {
			"success": false,
			"error": "NOT_ENOUGH_RESOURCES"
		}

	# The treasury must be able to receive the full payment first.
	var revenue = amount * get_price(resource_id)

	if city_treasury.get_capacity() - city_treasury.get_balance() < revenue:
		return {
			"success": false,
			"error": "TREASURY_CAPACITY"
		}

	if not resource_manager.remove_resource(resource_id, amount):
		return {
			"success": false,
			"error": "RESOURCE_TRANSFER_FAILED"
		}

	var accepted = city_treasury.add_money(revenue)

	if accepted != revenue:
		# Roll back the treasury and resource changes.
		if accepted > 0:
			city_treasury.spend(accepted)

		resource_manager.add_resource(resource_id, amount)

		return {
			"success": false,
			"error": "TREASURY_CAPACITY"
		}

	stock[resource_id] += amount

	return {
		"success": true,
		"product": resource_id,
		"amount": amount,
		"revenue": revenue,
		"stock": get_stock(resource_id),
		"treasury_balance": city_treasury.get_balance()
	}


func sell_to_customer(resource_id, amount, customer_money, building):
	if not PRODUCTS.has(resource_id):
		return {"success": false, "error": "INVALID_PRODUCT"}

	amount = int(amount)
	customer_money = int(customer_money)

	if amount <= 0:
		return {"success": false, "error": "INVALID_AMOUNT"}

	if typeof(building) != TYPE_DICTIONARY:
		return {"success": false, "error": "INVALID_BUILDING"}

	if str(building.get("id", "")) != "mineral_market":
		return {"success": false, "error": "NOT_A_MINERAL_MARKET"}

	if not can_supply(resource_id, amount):
		return {"success": false, "error": "NOT_ENOUGH_STOCK"}

	var total_cost = amount * get_sell_price(resource_id)

	if customer_money < total_cost:
		return {"success": false, "error": "CUSTOMER_CANNOT_AFFORD"}

	stock[resource_id] -= amount

	building["business_balance"] = int(
		building.get("business_balance", 0)
	) + total_cost

	building["last_revenue"] = int(
		building.get("last_revenue", 0)
	) + total_cost

	building["total_revenue"] = int(
		building.get("total_revenue", 0)
	) + total_cost

	print(
		"REAL MARKET SALE | Product: ", resource_id,
		" | Quantity: ", amount,
		" | Revenue: $", total_cost,
		" | Remaining stock: ", stock[resource_id]
	)

	return {
		"success": true,
		"product": resource_id,
		"amount": amount,
		"cost": total_cost,
		"remaining_money": customer_money - total_cost,
		"remaining_stock": get_stock(resource_id),
		"business_balance": building["business_balance"]
	}

	# Complete the transaction.
	stock[resource_id] -= amount

	# Record actual sales revenue in this store's account.
	building["business_balance"] = int(
		building.get("business_balance", 0)
	) + total_cost

	building["last_revenue"] = int(
		building.get("last_revenue", 0)
	) + total_cost

	building["total_revenue"] = int(
		building.get("total_revenue", 0)
	) + total_cost

	print(
		"REAL MARKET SALE | Product: ",
		resource_id,
		" | Quantity: ",
		amount,
		" | Revenue: $",
		total_cost,
		" | Business balance: $",
		building["business_balance"],
		" | Remaining stock: ",
		stock[resource_id]
	)

	return {
		"success": true,
		"product": resource_id,
		"amount": amount,
		"cost": total_cost,
		"remaining_money": customer_money - total_cost,
		"remaining_stock": get_stock(resource_id),
		"business_balance": building["business_balance"]
	}

func restore_stock(saved_stock):
	if typeof(saved_stock) != TYPE_DICTIONARY:
		return

	for resource_id in stock.keys():
		stock[resource_id] = max(
			0,
			int(saved_stock.get(resource_id, 0))
		)


func get_stock_data():
	return stock.duplicate(true)
