class_name CardPrices
extends RefCounted


signal prices_changed

var update_interval_seconds := 60.0
var volatility := 0.08

var _prices: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _save_path := GamePaths.SAVE_CARD_PRICES


func _init() -> void:
	_rng.randomize()


func load_prices(save_path: String = GamePaths.SAVE_CARD_PRICES) -> void:
	_save_path = save_path
	var data = ContentLoader.load_json(GamePaths.DATA_CARD_PRICES)
	if not (data is Dictionary) or not (data.get("prices") is Dictionary):
		push_error("Card prices could not be loaded from %s." % GamePaths.DATA_CARD_PRICES)
		return
	update_interval_seconds = maxf(float(data.get("update_interval_seconds", 60.0)), 1.0)
	volatility = clampf(float(data.get("volatility", 0.08)), 0.0, 1.0)
	_prices.clear()
	for card_id in data["prices"]:
		_prices[str(card_id)] = maxi(int(data["prices"][card_id]), 1)
	if FileAccess.file_exists(_save_path):
		var saved_data = ContentLoader.load_json(_save_path)
		if saved_data is Dictionary and saved_data.get("prices") is Dictionary:
			for card_id in _prices:
				if saved_data["prices"].has(card_id):
					_prices[card_id] = maxi(int(saved_data["prices"][card_id]), 1)
	prices_changed.emit()


func has_price(card_id: int) -> bool:
	return _prices.has(str(card_id))


func get_price(card_id: int) -> int:
	return int(_prices.get(str(card_id), 1))


func set_price(card_id: int, price: int) -> void:
	if not has_price(card_id) or price <= 0 or price == get_price(card_id):
		return
	_prices[str(card_id)] = price
	_save_prices()
	prices_changed.emit()


func fluctuate() -> void:
	var changed := false
	for card_id in _prices:
		var previous_price := int(_prices[card_id])
		var next_price := maxi(1, int(round(previous_price * (1.0 + _rng.randf_range(-volatility, volatility)))))
		_prices[card_id] = next_price
		changed = changed or next_price != previous_price
	if changed:
		_save_prices()
		prices_changed.emit()


func _save_prices() -> void:
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		push_error("Card prices could not be saved to %s." % _save_path)
		return
	file.store_string(JSON.stringify({"prices": _prices}, "\t"))
