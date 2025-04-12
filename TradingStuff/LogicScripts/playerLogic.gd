# player.gd
class_name Player
extends Trader

func _init(name: String, li: int, starting_cards: Array):
	super._init(name, li, starting_cards)

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
	
	for i in give:
		given.append(self.collection[i])
		income += int(self.collection[i].get_price() / counter.get_mult())
	for i in take:
		taken.append(counter.collection[i])
		income -= int(counter.collection[i].get_price() * counter.get_mult())
	
	self.LI += income
	counter.LI -= income
	var c = 0
	
	give.sort()
	give.reverse()
	for i in give:
		self.collection.remove_at(i)
		
	take.sort()
	take.reverse()
	for i in give:
		counter.collection.remove_at(i)
	
	for i in taken:
		self.collection.append(i)
	for i in given:
		counter.collection.append(i)
