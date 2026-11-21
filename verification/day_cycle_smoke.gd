extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := get_tree().root.get_node("GameState")
	var screen = load("res://scenes/screens/shop_table_screen.tscn").instantiate()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	var cycle: DayCycleManager = state.day_cycle
	var binder: CardBinder = screen._storage_binder
	var storage := binder.get_collection()
	var initial_cards := storage.get_cards()
	var initial_count := storage.get_count()
	assert(cycle.day == 1 and cycle.phase == DayCycleManager.Phase.DAY)
	assert(not cycle.start_next_day(storage))
	assert(not cycle.buy_offer(0).is_empty())
	screen.close_shop()
	assert(not screen.desk.visible and not screen.shop_view.visible)
	assert(not screen.desk.can_process())
	assert(cycle.offers.size() == 5)
	assert(not cycle.close_shop())
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://night_supply_preview.png")
	state.set_money(0)
	assert(cycle.buy_offer(0) == "Недостаточно денег.")
	assert(cycle.pending_orders.is_empty())
	assert(not cycle.offers[0]["purchased"])
	state.set_money(10000)
	var expected_balance := 10000
	var ordered: Array[Card] = []
	for index in range(cycle.offers.size()):
		var card := cycle.offers[index]["card"] as Card
		ordered.append(card)
		expected_balance -= int(cycle.offers[index]["price"])
		assert(cycle.buy_offer(index).is_empty())
		assert(not cycle.buy_offer(index).is_empty())
	assert(state.get_money() == expected_balance)
	assert(storage.get_count() == initial_count)
	assert(cycle.pending_orders.size() == 5)
	assert(not cycle.buy_offer(-1).is_empty())
	assert(not cycle.buy_offer(5).is_empty())
	screen.start_next_day()
	assert(cycle.day == 2 and cycle.phase == DayCycleManager.Phase.DAY)
	assert(screen.desk.visible and screen.desk.can_process())
	assert(cycle.pending_orders.is_empty())
	assert(storage.get_count() == initial_count + 5)
	for card in initial_cards + ordered:
		assert(storage.get_cards().has(card))
	for night in range(4):
		screen.close_shop()
		for index in range(cycle.offers.size()):
			assert(cycle.buy_offer(index).is_empty())
		screen.start_next_day()
	assert(cycle.day == 6)
	assert(storage.get_count() == initial_count + 25)
	assert(binder.page_count > 3)
	var count := storage.get_count()
	screen.start_next_day()
	assert(storage.get_count() == count and cycle.day == 6)
	# Existing extraction produces a normal draggable holding the same specimen.
	var specimen := ordered[0]
	var specimen_index := storage.get_slots().find(specimen)
	binder.reparent(screen.desk.drag_surface)
	binder.visible = true
	screen.desk.drag_surface.register_draggable(binder.get_node("UIDraggable"))
	binder.set_drag_space(&"desk")
	binder._current_page = specimen_index / CardBinder.SLOTS_PER_PAGE
	binder.refresh_storage()
	binder._extract_card(specimen_index % CardBinder.SLOTS_PER_PAGE, Vector2(-1000, -1000))
	assert(storage.get_card(specimen_index) == null)
	var found := false
	for child in binder.get_parent().get_children():
		if child is DraggableCard and child.get_card_data() == specimen:
			found = true
	assert(found)
	screen.close_shop()
	screen.start_next_day()
	assert(storage.get_count() == count - 1)
	var buyer := CustomerVisit.new(1, 5, 1000, 0)
	var trade := CustomerTradeController.new()
	trade.begin_visit(buyer)
	trade.receive_card(specimen)
	var balance_before_sale: int = state.get_money()
	trade.receive_ask(&"ASK", 1)
	assert(buyer.cards_on_hands.has(specimen))
	assert(state.get_money() == balance_before_sale + 1)
	print("DAY_CYCLE_SMOKE_OK: purchases, funds, identity, delivery, growth, extraction, sale, 6 cycles")
	screen.queue_free()
	await get_tree().process_frame
	get_tree().quit()
