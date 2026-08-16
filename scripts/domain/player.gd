# player.gd
class_name Player
extends Trader

var total_trade_volume: int = 0

func _init(name: String, li: int, starting_cards: Array, portrait: Resource, rank: int, suit: String, 
event_price_modifier: float, trader_mult: float, dialogue: String):
	super(name, li, starting_cards, portrait, rank, suit, event_price_modifier, trader_mult, dialogue)
	
func priceCount(counter: Trader, give: Array[int], take: Array[int]) -> int:
	for i in give:
		if i >= len(self.collection) or i < 0:
			print("Bad given card indices")
			return -1
	
	for i in take:
		if i >= len(counter.collection) or i < 0:
			print("Bad taken card indices")
			return -1
			
	var given = []
	var taken = []
	
	var income : int = 0
	var trade_mult = counter.get_price_multiplier_against(self.rank)
	
	for i in give:
		given.append(self.collection[i])
		if trade_mult != 0: income += int(self.collection[i].base_price / trade_mult)
	for i in take:
		taken.append(counter.collection[i])
		if trade_mult != 0: income -= int(counter.collection[i].base_price * trade_mult)
	
	
	return income

func trade(counter: Trader, give: Array[int], take: Array[int]) -> void:
	for i in give:
		if i >= len(self.collection) or i < 0:
			print("Bad given card indices")
			return
	
	for i in take:
		if i >= len(counter.collection) or i < 0:
			print("Bad taken card indices")
			return
			
	var given = []
	var taken = []
	var income : int = 0
	var trade_mult = counter.get_price_multiplier_against(self.rank)
	print (trade_mult)
	for i in give:
		if trade_mult != 0:
			given.append(self.collection[i])	
			income += int(self.collection[i].base_price / trade_mult)
			total_trade_volume += int(self.collection[i].base_price / trade_mult)
		else: given.append(self.collection[i])
	for i in take:
		if trade_mult != 0:
			taken.append(counter.collection[i])
			income -= int(counter.collection[i].base_price * trade_mult)
			total_trade_volume += int(counter.collection[i].base_price / trade_mult)
		else: taken.append(counter.collection[i])
		
		
	if self.LI + income < 0:
		print("Player can't afford this trade.")
		return
	if counter.LI - income < 0:
		print("Trader can't afford this trade.")
		return
	
	self.LI += income
	counter.LI -= income
	var c = 0
	
	if self.rank < Globals.CardRanks.ACE and total_trade_volume>=500*(self.rank + 1):
		self.rank += 1
		total_trade_volume = 0

	
	give.sort()
	give.reverse()
	for i in give:
		self.collection.remove_at(i)
		
	take.sort()
	take.reverse()
	for i in take:
		counter.collection.remove_at(i)
	
	for i in taken:
		self.collection.append(i)
	for i in given:
		counter.collection.append(i)
