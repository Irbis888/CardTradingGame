# player.gd
class_name Player
extends Trader

var total_trade_volume: int = 0

func _init(name: String, li: int, starting_cards: Array, portrait: Resource, rank: int, suit: String, event_price_modifier: float):
	super(name, li, starting_cards, portrait, rank, suit, event_price_modifier)
	
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
		#income += int(self.collection[i].base_price / counter.get_mult())
		income += int(self.collection[i].base_price / trade_mult)
	for i in take:
		taken.append(counter.collection[i])
		#income -= int(counter.collection[i].base_price * counter.get_mult())
		income -= int(counter.collection[i].base_price * trade_mult)
	
	
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
	
	for i in give:
		given.append(self.collection[i])
		#income += int(self.collection[i].base_price / counter.get_mult())
		income += int(self.collection[i].base_price / trade_mult)
		total_trade_volume += int(self.collection[i].base_price / counter.get_mult())
	for i in take:
		taken.append(counter.collection[i])
		#income -= int(counter.collection[i].base_price * counter.get_mult())
		income -= int(counter.collection[i].base_price * trade_mult)
		total_trade_volume += int(counter.collection[i].base_price / counter.get_mult())
	
	self.LI += income
	counter.LI -= income
	var c = 0
	
	if self.rank < Globals.CardRanks.ACE and total_trade_volume>=1000*(self.rank + 1):
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
