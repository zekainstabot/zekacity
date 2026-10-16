
extends Reference

# ZekaCity - CityTreasury.gd
# Godot 3.6
# خزانه و ظرفیت پول شهرداری

var starting_money = 10000
var base_capacity = 10000
var central_bank_bonus = 40000
var municipal_bank_bonus = 5000

var balance = 10000
var locked_money = 0

var central_bank_built = false
var central_bank_rebuild_days_left = 0

var municipal_banks = []


func get_capacity():
	var capacity = base_capacity

	if central_bank_built:
		capacity += central_bank_bonus

	capacity += municipal_banks.size() * municipal_bank_bonus

	return capacity


func get_balance():
	return balance


func get_available_money():
	return max(0, balance - locked_money)


func get_locked_money():
	return locked_money


func can_afford(amount):
	return amount >= 0 and get_available_money() >= amount


func spend(amount):
	if not can_afford(amount):
		return false

	balance -= amount
	_recalculate_locked_money()
	return true


func add_money(amount):
	if amount <= 0:
		return 0

	var available_space = max(0, get_capacity() - balance)
	var accepted = min(amount, available_space)

	balance += accepted
	_recalculate_locked_money()

	return accepted


func build_central_bank():
	if central_bank_built:
		return false

	if central_bank_rebuild_days_left <= 0 and _has_expired_central_bank():
		return false

	central_bank_built = true
	central_bank_rebuild_days_left = 0
	_recalculate_locked_money()

	return true


func demolish_central_bank():
	if not central_bank_built:
		return false

	central_bank_built = false
	central_bank_rebuild_days_left = 7
	_recalculate_locked_money()

	return true


func advance_game_day():
	if central_bank_built:
		return

	if central_bank_rebuild_days_left <= 0:
		return

	central_bank_rebuild_days_left -= 1

	if central_bank_rebuild_days_left == 0:
		_destroy_excess_money()


func add_municipal_bank(bank_key):
	if bank_key == null or bank_key == "":
		return false

	if bank_key in municipal_banks:
		return false

	municipal_banks.append(bank_key)
	_recalculate_locked_money()

	return true


func remove_municipal_bank(bank_key):
	var index = municipal_banks.find(bank_key)

	if index == -1:
		return false

	municipal_banks.remove(index)
	_recalculate_locked_money()

	return true


func _recalculate_locked_money():
	locked_money = max(0, balance - get_capacity())


func _destroy_excess_money():
	balance = min(balance, get_capacity())
	locked_money = 0


func _has_expired_central_bank():
	return false
