extends Node


signal money_changed(balance: int)

const INITIAL_MONEY := 1000

var _wallet := ShopWallet.new(INITIAL_MONEY)


func _ready() -> void:
	_wallet.balance_changed.connect(_on_wallet_balance_changed)


func get_money() -> int:
	return _wallet.get_balance()


func set_money(value: int) -> void:
	_wallet.set_balance(value)


func add_money(amount: int) -> void:
	_wallet.add_money(amount)


func try_spend(amount: int) -> bool:
	return _wallet.try_spend(amount)


func _on_wallet_balance_changed(balance: int) -> void:
	money_changed.emit(balance)
