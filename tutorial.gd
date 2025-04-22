extends Control

var strs = ["Welcome back, boss.
Hang your coat, kill the cigar, and keep your ears open—this is your one shot to claw your way back to the top of the cardboard syndicate.",
"The story that still smells of smoke

You were the Don of Cardia Nostra until your “blood brother” Ricky Double‑Fold slid a knife into your spine and walked off with every rare card in your vault. Four legendary pieces—EraemEreff, Crimson Heart, Goat Exorcist of the Azure Blaze, Pig'o'Boros—are now decorating his greasy hands. Bring them home and Ricky’s breathing privileges expire.",
"Respect is printed on cardboard

Around here, nobody cares how many bullets you own—only how many rares sit in your binder. A thick album means low bows. Lose cards, lose face. Remember that when you haggle.",
"The pecking order

Street Pawn (6–10): folks call him “kid.”

Jack (J): a common runner, does the dirty pickups.

Queen (Q): “Signora,” pulls strings from velvet gloves.

King (K): “Don” or “Donna,” controls a whole district.

Ace (A): that’s you—once the crown is back on your head.


Higher rank unlocks fatter deals and deeper whispers.",
"How a day flows in Cardia Nostra

1. Street Report – A random event twists prices. Rarity, set hype, character fame, trader reputation, and each card’s stats get shaken into one volatile cocktail.


2. The Deal – Buy, swap, intimidate. The tougher your table talk, the sweeter the margin. Watch for scams.


3. Night Count – The accountant tallies your profit, the current value of your collection, and the bump to your rep.



Three beats make a day; a few days make an empire. Ignore the Street Report and you’ll overpay. Miss a deal and your rival steals the card of your dreams. Sleep on the Night Count and you won’t notice someone slowly stripping you bare.",
"Street rules etched in cardstock

1. Never flash your whole hand. A glimpse of two rares is enough to raise the stakes.


2. Good connections cost less than good cards. Before spending cash, lean on your aura.


3. Collect intel the way you collect foils. Someone out there knows where your legends hide.


4. Betrayal is paid in full. Once the four trophies return, the Reckoning Phase with Ricky begins—and cardboard gives way to cold steel.",
"Take back what the world stole. Cards are your gun; the binder is your holster.
Now deal the first hand, Don—time to reshuffle the city."]

var page = 0

func  _ready() -> void:
	set_label_text()

func set_label_text():
	$TextureRect/Label.text = strs[page]


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_prev_page_pressed() -> void:
	page = max(0, page - 1)
	set_label_text()


func _on_next_page_pressed() -> void:
	page = min(len(strs)-1, page + 1)
	set_label_text()
