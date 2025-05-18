extends Node

var current_event = null

var all_events: Array = []
var queued_event_id: int = -1

func _ready():
	load_events()
	pick_random_event()
	
func set_queued(q: int):
	queued_event_id = q

func load_events():
	all_events = Globals.load_json_file("res://Resources/events.json")
	if all_events == null:
		all_events = []

func pick_random_event():
	if all_events.is_empty():
		current_event = {}
		return
		
	var non_story_events = []
	for event in all_events:
		if not event.has("is_story"): 
			non_story_events.append(event)

	if non_story_events.is_empty():
		current_event = {}
		print("No non-story events available.")
		return

	current_event = non_story_events.pick_random()
	print("i chose you", current_event.name)
	#apply_event(current_event)
	
func get_event_by_id(id: int) -> Dictionary:
	for event in all_events:
		if event.has("id") and event.id == id:
			return event
	return {} 


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
