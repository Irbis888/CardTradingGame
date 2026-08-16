extends Node


var traderList : Array[Trader] 
var cardList: Array[Card]
var quest_manager: QuestManager
var current_ending: Dictionary = {}


var content: Dictionary = {}
var nameList: Array = []
var dialoguesNeutral: Array = []
var dialogueRude: Array = []
var dialoguesFlatter: Array = []
var day: int = 0

enum CardRanks {
		SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE
}

var CardNames: Array = []
var CardSuits: Array = []

var NextPic: Resource = load(GamePaths.DEFAULT_STORY_IMAGE)
var NextText: String = ""
var is_next_to_trade = true

var story_traders: Array = []

func load_story_traders():
	var data = ContentLoader.load_json(GamePaths.DATA_STORY_TRADERS)
	if data != null:
		story_traders = data
	else:
		push_warning("Story trader data could not be loaded.")

func add_story_traders_for_current_day():
	for trader_data in Globals.story_traders:
		for appearance in trader_data.appearances:
			if appearance.day == Globals.day:
				
				if appearance.has("required_tag") and appearance.has("required_tag_count"):
					var tag = appearance.required_tag
					var needed = appearance.required_tag_count
					if Globals.quest_manager.count_completed_quests_with_tag(tag) < needed:
						continue  # игрок еще не выполнил достаточно квестов с этим тегом
				
				var quest_id = appearance.get("quest_id", null)
			
				if quest_id != null:
					var quest = quest_manager.get_quest_by_id(quest_id)
					if quest == null:
						continue

				#	 Если у квеста есть prev_quest_id и он не выполнен — пропускаем NPC
					if quest.has("prev_quest_id") and not quest_manager.is_quest_completed(quest.prev_quest_id):
						continue
				
				if appearance.has("required_quest_id"):
					quest_id = appearance.required_quest_id
					if not quest_manager.is_quest_completed(quest_id):
						continue  # Квест не завершён — пропустить это появление
				
				var cards = []
				for card_id in appearance.cards:
					var card = Globals.get_card_by_id(card_id)
					if card != null:
						cards.append(card)
			
				var portrait_path = GamePaths.portrait(trader_data.portrait)
				var portrait = load(portrait_path)
				
				var rank: int
				if appearance.has("rank"):
					rank = appearance.rank
				else:
					rank = trader_data.rank
					
				var money: int
				if appearance.has("money"):
					money = appearance.money
				else:
					money = trader_data.money

				var story_trader = Trader.new(
					trader_data.name,
					money,
					cards,
					portrait,
					rank,
					trader_data.suit,
					1.0,
					trader_data.mult,
					appearance.dialogue
				)
				Globals.traderList.append(story_trader)
		

func generate_traders():
	var weights = Globals.get_rank_weights_for(Globals.playerAccount.rank)
	
	while Globals.traderList.size() != 4:
		var pn = randi_range(2, 9)
		var portrait = load(GamePaths.portrait("M" + str(pn) + ".png"))
		var gangName = Globals.nameList.pick_random()
		var coll = []
		var dialogue: String


		var trader_rank = Globals.choose_weighted_rank(weights)
		var rand_suit = Globals.CardSuits[randi_range(0, 3)]
		for j in range(randi_range(4, 10)):
			coll.append(Globals.choose_card_for_rank(trader_rank))
			
		if trader_rank - Globals.playerAccount.rank >= 2:
			dialogue = Globals.dialogueRude.pick_random()
		elif trader_rank - Globals.playerAccount.rank <= -2:
			dialogue = Globals.dialoguesFlatter.pick_random()
		else:
			dialogue = Globals.dialoguesNeutral.pick_random()	
			
		
		Globals.traderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait, trader_rank,
		 rand_suit, 1.0, 1.0, dialogue))

# Controls how frequently each trader rank appears for the current player rank.

func get_rank_weights_for(player_rank: int) -> Dictionary:
	var weights := {
		Globals.CardRanks.SIX: 10,
		Globals.CardRanks.SEVEN: 10,
		Globals.CardRanks.EIGHT: 10,
		Globals.CardRanks.NINE: 10,
		Globals.CardRanks.TEN: 10,
		Globals.CardRanks.JACK: 5,
		Globals.CardRanks.KING: 5,
		Globals.CardRanks.QUEEN: 5,
		Globals.CardRanks.ACE: 5,
	}

	if player_rank < Globals.CardRanks.JACK:
		weights[Globals.CardRanks.QUEEN] = 3
		weights[Globals.CardRanks.KING] = 2
		weights[Globals.CardRanks.ACE] = 0

	return weights

static func choose_weighted_rank(weights: Dictionary) -> int:
	var total_weight = 0
	for w in weights.values():
		total_weight += w
	
	var rand = randi_range(0, total_weight - 1)
	var cumulative = 0
	
	for rank in weights.keys():
		cumulative += weights[rank]
		if rand < cumulative:
			return rank
	
	return weights.keys()[0]  # Fallback for an empty traversal.

var my_collection = []
var playerAccount : Player
var nextTrader: Trader

# Card rarity distribution depends on the trader rank.

func get_weight_for_card(card: Card, rank: int) -> int:
	if rank == CardRanks.ACE:
		return card.rarity * 5
	elif rank >= CardRanks.QUEEN:
		return card.rarity * 3
	elif rank >= CardRanks.TEN:
		return card.rarity * 2
	else:
		return 6 - card.rarity  # чаще выпадут дешёвые
		

func choose_card_for_rank(rank: int) -> Card:
	var weighted_cards := []
	for card in cardList:
		var weight := get_weight_for_card(card, rank)
		for i in range(weight):
			weighted_cards.append(card)
	return weighted_cards.pick_random()


func _ready() -> void:
	load_text_content()
	create_cards()
	generate_collection(3)
	playerAccount = Player.new(content.player.name, 4200, my_collection, load(GamePaths.PLAYER_PORTRAIT),
	Globals.CardRanks.NINE, content.player.starting_suit, 1.0, 1.0, "")
	load_story_traders()
	quest_manager = QuestManager.new()
	add_child(quest_manager)
	

func has_all_ssp_cards() -> bool:
	var required_ids := [34, 35, 36, 37]
	var owned_ids := []

	for card in playerAccount.collection:
		var card_id = card.id
		if card_id in required_ids and card_id not in owned_ids:
			owned_ids.append(card_id)

	return owned_ids.size() == 4

	
func generate_collection(size:int):
		for i in size:
			my_collection.append(cardList.pick_random())
	
	
func create_cards () -> void:
	var cards_data = ContentLoader.load_json(GamePaths.DATA_CARDS)
	if cards_data:
		for i in cards_data:
			var c = Card.new(i["name"], load(GamePaths.card_image(i["picture"])),
			i["attack"], i["defense"], i["magic"], i["series"], i["rarity"], i["id"] )
			cardList.append(c)
			
func get_card_by_id(id: int) -> Card:
	for c in cardList:
		if c.id == id:
			return c
	return null
	
func load_text_content() -> void:
	content = ContentLoader.load_json(GamePaths.DATA_TEXT)
	nameList = content.traders.random_names
	dialoguesNeutral = content.traders.dialogue.neutral
	dialogueRude = content.traders.dialogue.rude
	dialoguesFlatter = content.traders.dialogue.flattering
	CardNames = content.cards.rank_names
	CardSuits = content.cards.suits
	NextText = content.story.intro