extends Node

var current_event = null

var all_events: Array = []

func _ready():
	load_events()
	pick_random_event()

func load_events():
	all_events = Globals.load_json_file("res://Resources/events.json")
	if all_events == null:
		all_events = []

func pick_random_event():
	if all_events.is_empty():
		current_event = {}
		return
	current_event = all_events.pick_random()
	print("i chose you", current_event.name)
	#apply_event(current_event)

func apply_event(event: Dictionary) -> void:
	if current_event == null:
		return

	match current_event["type"]:
		"suit_price_modifier":
			var target_suit = current_event["target_suit"]
			var multiplier = current_event["price_multiplier"]
			for trader in Globals.traderList:
				if trader.suit == target_suit:
					trader.event_price_modifier = multiplier
					print("Applying to trader:", trader.name)
					print(trader.event_price_modifier)
					
		"rank_price_modifier":
			var target_rank = current_event["target_rank"]
			var multiplier = current_event["price_multiplier"]
			for trader in Globals.traderList:
				if trader.rank == target_rank:
					trader.event_price_modifier = multiplier
					print("Applying to trader:", trader.name)
					print(trader.event_price_modifier)
		"flavor_only":
			# Просто отображаем текст, без изменений
			pass
