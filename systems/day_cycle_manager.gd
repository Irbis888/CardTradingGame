class_name DayCycleManager
extends RefCounted


enum Phase { DAY, NIGHT }

const SUPPLIER_STOCK := [
	{"card_id": 0, "price": 80},
	{"card_id": 1, "price": 120},
	{"card_id": 9, "price": 160},
	{"card_id": 16, "price": 220},
	{"card_id": 24, "price": 300},
]

var day := 1
var phase: Phase = Phase.DAY
var offers: Array[Dictionary] = []
var pending_orders: Array[Card] = []


func close_shop() -> bool:
	if phase != Phase.DAY:
		return false
	offers.clear()
	for entry in SUPPLIER_STOCK:
		var card := CardDatabase.create_card(int(entry["card_id"]))
		if card != null:
			offers.append({"card": card, "price": int(entry["price"]), "purchased": false})
	phase = Phase.NIGHT
	return true


func buy_offer(index: int) -> String:
	if phase != Phase.NIGHT:
		return "Закупки доступны только ночью."
	if index < 0 or index >= offers.size():
		return "Предложение недоступно."
	var offer := offers[index]
	if bool(offer["purchased"]):
		return "Этот экземпляр уже заказан."
	if not GameState.try_spend(int(offer["price"])):
		return "Недостаточно денег."
	pending_orders.append(offer["card"] as Card)
	offer["purchased"] = true
	return ""


func start_next_day(storage: CardCollection) -> bool:
	if phase != Phase.NIGHT or storage == null:
		return false
	for card in pending_orders:
		storage.store_first_available(card, 6)
	pending_orders.clear()
	day += 1
	phase = Phase.DAY
	return true
