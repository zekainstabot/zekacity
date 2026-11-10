extends Reference

# ZekaCity - ResourceManager.gd
# Godot 3.6
# مدیریت موجودی منابع با ظرفیت مشترک انبارها

var amounts = {
	"stone": 0,
	"iron_ore": 0,
	"wood": 0,
	"lumber": 0,
	"furniture": 0
}

var storage_system = null


func set_storage_system(system):
	storage_system = system


func add_resource(resource_id, amount):
	if not amounts.has(resource_id):
		return false

	var requested_amount = int(amount)
	if requested_amount <= 0:
		return false

	# Resource transfers are atomic: never add a partial quantity and
	# then return false. Callers can safely roll back only when this
	# function reports success, and storage capacity remains predictable.
	if storage_system != null:
		if storage_system.get_free_capacity(self) < requested_amount:
			return false

	amounts[resource_id] += requested_amount
	return true


func remove_resource(resource_id, amount):
	if not amounts.has(resource_id):
		return false

	if amount <= 0:
		return false

	if int(amounts[resource_id]) < int(amount):
		return false

	amounts[resource_id] -= int(amount)
	return true


func get_amount(resource_id):
	return int(amounts.get(resource_id, 0))


func get_total_amount():
	var total = 0

	for resource_id in amounts.keys():
		total += int(amounts[resource_id])

	return total


func get_all_amounts():
	return amounts.duplicate(true)
