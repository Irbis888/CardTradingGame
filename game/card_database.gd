extends Node


var card_ui_text: Dictionary = {}
var cards: Array[Card] = []
var prices := CardPrices.new()

var _cards_by_id: Dictionary = {}


func _ready() -> void:
	_load_card_ui_text()
	prices.load_prices()
	_load_cards()
	var price_timer := Timer.new()
	price_timer.name = "PriceTimer"
	price_timer.wait_time = prices.update_interval_seconds
	price_timer.timeout.connect(prices.fluctuate)
	add_child(price_timer)
	price_timer.start()


func get_card_by_id(card_id: int) -> Card:
	return _cards_by_id.get(card_id) as Card


func get_cards() -> Array[Card]:
	return cards.duplicate()


func _load_card_ui_text() -> void:
	var text_data = ContentLoader.load_json(GamePaths.DATA_TEXT)
	if not (text_data is Dictionary) or not text_data.has("ui"):
		push_error("Card UI text could not be loaded from %s." % GamePaths.DATA_TEXT)
		card_ui_text = {}
		return
	card_ui_text = text_data["ui"]


func _load_cards() -> void:
	cards.clear()
	_cards_by_id.clear()

	var cards_data = ContentLoader.load_json(GamePaths.DATA_CARDS)
	if not (cards_data is Array):
		push_error("Card data could not be loaded from %s." % GamePaths.DATA_CARDS)
		return

	for card_data in cards_data:
		if not (card_data is Dictionary):
			push_warning("Skipped malformed card entry: %s" % [card_data])
			continue

		var card := Card.new(
			str(card_data.get("name", "")),
			load(GamePaths.card_image(str(card_data.get("picture", "")))) as Texture2D,
			str(card_data.get("series", "")),
			int(card_data.get("rarity", 0)),
			int(card_data.get("id", -1)),
			prices,
			str(card_data.get("description", "")),
			card_data.get("trivia", {}) if card_data.get("trivia", {}) is Dictionary else {}
		)
		if not prices.has_price(card.id):
			push_warning("Card %d has no market price in %s; using $1." % [card.id, GamePaths.DATA_CARD_PRICES])
		cards.append(card)
		_cards_by_id[card.id] = card
