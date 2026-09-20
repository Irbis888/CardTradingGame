class_name ShopMoneyCounter
extends PanelContainer


@onready var amount_label: Label = $Margin/AmountLabel


func _ready() -> void:
	GameState.money_changed.connect(_refresh_amount)
	_refresh_amount(GameState.get_money())


func _refresh_amount(amount: int) -> void:
	amount_label.text = "$%d" % amount
