class_name TradingDesk
extends Control


@onready var card_binder: CardBinder = $DragSurface/CardBinder
@onready var cash_register: CashRegister = $DragSurface/CashRegister
@onready var customer_manager: CustomerManager = $VisitorArea/CustomerManager


func get_card_binder() -> CardBinder:
	return card_binder


func get_cash_register() -> CashRegister:
	return cash_register


func get_customer_manager() -> CustomerManager:
	return customer_manager
