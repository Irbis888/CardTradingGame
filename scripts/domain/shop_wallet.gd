class_name ShopWallet
extends RefCounted


signal balance_changed(balance: int)

var _balance: int


func _init(initial_balance: int = 0) -> void:
	_balance = maxi(initial_balance, 0)


func get_balance() -> int:
	return _balance


func set_balance(value: int) -> void:
	var next_balance := maxi(value, 0)
	if _balance == next_balance:
		return
	_balance = next_balance
	balance_changed.emit(_balance)


func add_money(amount: int) -> void:
	if amount > 0:
		set_balance(_balance + amount)


func try_spend(amount: int) -> bool:
	if amount < 0 or amount > _balance:
		return false
	set_balance(_balance - amount)
	return true
