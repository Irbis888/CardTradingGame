extends Control


signal next_day_requested

var _heading: Label
var _balance: Label
var _orders: Label
var _message: Label
var _list: VBoxContainer


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.055, 0.045, 0.035)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	_heading = _label("", 30)
	column.add_child(_heading)
	_balance = _label("", 24)
	column.add_child(_balance)
	column.add_child(_label("Поставщик · По одному экземпляру каждого предложения за ночь", 20))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	_orders = _label("", 20)
	column.add_child(_orders)
	_message = _label("", 20)
	_message.custom_minimum_size.y = 28
	column.add_child(_message)
	var next_day := Button.new()
	next_day.text = "Начать следующий день"
	next_day.custom_minimum_size.y = 54
	next_day.pressed.connect(func(): next_day_requested.emit())
	column.add_child(next_day)
	GameState.money_changed.connect(_on_money_changed)


func refresh() -> void:
	_heading.text = "Ночь после дня %d · Закупка карт" % GameState.day_cycle.day
	_message.text = "Заказы придут утром в альбом из подстольного хранилища."
	_refresh_offers()


func _refresh_offers() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for index in range(GameState.day_cycle.offers.size()):
		var offer := GameState.day_cycle.offers[index]
		var card := offer["card"] as Card
		var panel := PanelContainer.new()
		_list.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		panel.add_child(row)
		var art := TextureRect.new()
		art.texture = card.picture
		art.custom_minimum_size = Vector2(90, 115)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(art)
		var name_label := _label(card.name, 24)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_label("$%d" % int(offer["price"]), 24))
		var buy := Button.new()
		buy.text = "Заказано" if bool(offer["purchased"]) else "Купить"
		buy.disabled = bool(offer["purchased"])
		buy.custom_minimum_size.x = 180
		buy.pressed.connect(_buy.bind(index))
		row.add_child(buy)
	_on_money_changed(GameState.get_money())
	var names := PackedStringArray()
	for card in GameState.day_cycle.pending_orders:
		names.append(card.name)
	_orders.text = "Ожидают доставки: %d%s" % [
		names.size(), " · " + ", ".join(names) if not names.is_empty() else "",
	]
	_orders.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _buy(index: int) -> void:
	var error := GameState.day_cycle.buy_offer(index)
	_message.text = error if not error.is_empty() else "Заказ оплачен. Доставка — в начале следующего дня."
	_refresh_offers()


func _on_money_changed(balance: int) -> void:
	_balance.text = "Баланс: $%d" % balance


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label
