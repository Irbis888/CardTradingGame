extends Node

#А нихуя тут пока нет

class_name QuestManager

# Загруженные из JSON все квесты
var all_quests: Array = []

# Активные на текущий день
var active_quests: Array = []

# Выполненные квесты
var completed_quests: Array = []

func _ready():
	load_quests()

func load_quests():
	var data = Globals.load_json_file("res://Resources/quests.json")
	if data:
		all_quests = data

func get_quests_for_day(day: int) -> Array:
	var today = []
	for quest in all_quests:
		if quest.day == day:
			
			if quest.has("prev_quest_id") and not is_quest_completed(quest.prev_quest_id):
				continue
				
			today.append(quest)
			print("got quest ", quest.name)
	active_quests = today
	return today

func card_matches_conditions(card: Card, conditions: Dictionary) -> bool:
	if "min_attack" in conditions and card.attack < conditions["min_attack"]:
		return false
	if "min_defense" in conditions and card.defense < conditions["min_defense"]:
		return false
	if "min_magic" in conditions and card.magic < conditions["min_magic"]:
		return false
	if "id" in conditions and card.id != conditions["id"]:
		return false
	if "rarity" in conditions and card.rarity != conditions["rarity"]:
		return false
	if "series" in conditions and card.series != conditions["series"]:
		return false
	return true

func trader_has_card_that_matches(trader: Trader, conditions: Dictionary) -> bool:
	for card in trader.collection:
		if card_matches_conditions(card, conditions):
			return true
	return false
	
func find_trader_by_name(traders: Array, name: String) -> Trader:
	for t in traders:
		if t.name == name:
			return t
	return null
	
func player_has_card_that_matches(conditions: Dictionary) -> bool:
	for card in Globals.playerAccount.collection:
		if card_matches_conditions(card, conditions):
			print("la la la ", card.name)
			return true
	return false

func check_quests_end_of_day(traders: Array) -> void:
	for story_npc in Globals.story_traders:
		for appearance in story_npc.appearances:
			if appearance.day != Globals.day:
				continue

			if not appearance.has("quest_id"):
				continue

			var quest_id = appearance.quest_id
			var quest = null
			for q in active_quests:
				if q.id == quest_id:
					quest = q
					break

			if quest == null or quest.get("completed", false):
				continue

			# Находим соответствующего торговца в traderList
			var trader = null
			for t in traders:
				if t.name == story_npc.name:
					trader = t
					break
			if trader == null:
				continue

			# Проверяем условия квеста
			var completed := false
			match quest.get("type", "give_card"):
				"give_card":
					completed = trader_has_card_that_matches(trader, quest.required_card_conditions)
				"receive_card":
					completed = player_has_card_that_matches(quest.required_card_conditions)

			if completed:
				quest.completed = true
				quest.completed_day = Globals.day
				completed_quests.append(quest)
				print("Quest completed: ", quest.name)
				
				if quest.has("reward_event_id"):
					EventManager.set_queued(quest.reward_event_id)
				
			else: print("Quest failed: ", quest.name)


func mark_quest_completed(quest: Dictionary):
	if not completed_quests.has(quest):
		completed_quests.append(quest)

func is_quest_completed(id: int) -> bool:
	for quest in completed_quests:
		if quest.id == id:
			return true
	return false

func get_completed_quests_for_day(day: int) -> Array:
	var quests = []
	for quest in completed_quests:
		if quest.has("next_npc_day") and quest.next_npc_day == day:
			quests.append(quest)
	return quests
	
func get_quest_by_id(id: int) -> Dictionary:
	for quest in all_quests:
		if quest.get("id", -1) == id:
			return quest
	return {}  # Возвращает пустой словарь, если квест не найден
	
func count_completed_quests_with_tag(tag: String) -> int:
	var count := 0
	for quest in completed_quests:
		if quest.has("tag") and quest.tag == tag:
			count += 1
	return count
