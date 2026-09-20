class_name CardCollection
extends RefCounted


signal changed

var _slots: Array[Card] = []


func _init(capacity: int = 0) -> void:
	_slots.resize(maxi(capacity, 0))


func get_capacity() -> int:
	return _slots.size()


func get_count() -> int:
	var count := 0
	for card in _slots:
		if card != null:
			count += 1
	return count


func get_card(index: int) -> Card:
	return _slots[index] if _is_valid_index(index) else null


func is_slot_empty(index: int) -> bool:
	return _is_valid_index(index) and _slots[index] == null


func store_at(index: int, card: Card) -> bool:
	if card == null or not is_slot_empty(index):
		return false
	_slots[index] = card
	changed.emit()
	return true


func take_at(index: int) -> Card:
	if not _is_valid_index(index):
		return null
	var card := _slots[index]
	if card == null:
		return null
	_slots[index] = null
	changed.emit()
	return card


func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for card in _slots:
		if card != null:
			cards.append(card)
	return cards


func get_slots() -> Array[Card]:
	return _slots.duplicate()


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _slots.size()
