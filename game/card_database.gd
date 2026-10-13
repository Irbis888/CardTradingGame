extends Node


var card_ui_text: Dictionary = {}
var cards: Array[CardDefinition] = []
var prices := CardPrices.new()
var specimen_profiles: Dictionary = {}

var _cards_by_id: Dictionary = {}


func _ready() -> void:
	_load_card_ui_text()
	prices.load_prices()
	_load_cards()
	var profile_data = ContentLoader.load_json(GamePaths.DATA_CARD_SPECIMENS)
	if profile_data is Dictionary:
		specimen_profiles = profile_data
	var price_timer := Timer.new()
	price_timer.name = "PriceTimer"
	price_timer.wait_time = prices.update_interval_seconds
	price_timer.timeout.connect(prices.fluctuate)
	add_child(price_timer)
	price_timer.start()


func get_card_by_id(card_id: int) -> Card:
	return create_card(card_id)


func create_card(card_id: int, properties: Dictionary = {}) -> Card:
	var definition := _cards_by_id.get(card_id) as CardDefinition
	return Card.new(definition, properties) if definition != null else null


func create_card_from_profile(card_id: int, profile: String) -> Card:
	if not profile.is_empty() and not specimen_profiles.has(profile):
		push_warning("Unknown specimen profile: %s" % profile)
		return null
	return create_card(card_id, specimen_profiles.get(profile, {}))


func restore_card(data: Dictionary) -> Card:
	return create_card(int(data.get("card_id", -1)), data)


func get_cards() -> Array[Card]:
	var result: Array[Card] = []
	for definition in cards:
		result.append(Card.new(definition))
	return result


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

		var card := CardDefinition.new(
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
