class_name ShopMoneyCounter
extends PanelContainer


@export_range(0, 1000000000, 1, "or_greater") var initial_money := 1000

@onready var amount_label: Label = $Margin/AmountLabel

var _wallet: ShopWallet


func _ready() -> void:
	_wallet = ShopWallet.new(initial_money)
	_wallet.balance_changed.connect(_refresh_amount)
	_refresh_amount(_wallet.get_balance())


func get_money() -> int:
	return _wallet.get_balance()


func set_money(value: int) -> void:
	_wallet.set_balance(value)


func add_money(amount: int) -> void:
	_wallet.add_money(amount)


func try_spend(amount: int) -> bool:
	return _wallet.try_spend(amount)


func _refresh_amount(amount: int) -> void:
	amount_label.text = "$%d" % amount
