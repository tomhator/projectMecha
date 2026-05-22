extends SceneTree

const CORE_SELECT_SCENE_PATH: String = "res://Scenes/CoreSelect/CoreSelectScene.tscn"

var _failed: bool = false


func _initialize() -> void:
	var packed := load(CORE_SELECT_SCENE_PATH) as PackedScene
	if packed == null:
		_assert_true(false, "CoreSelect scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate() as Control
	if scene == null:
		_assert_true(false, "CoreSelect scene failed to instantiate")
		quit(1)
		return
	root.add_child(scene)
	await process_frame

	_check_sortie_view(scene)

	scene.call("_show_research_view")
	await process_frame
	_check_research_view(scene)

	scene.queue_free()
	if _failed:
		push_error("CoreSelect layout: FAIL")
		quit(1)
		return
	print("CoreSelect layout: PASS")
	quit()


func _check_sortie_view(scene: Control) -> void:
	_assert_true(scene.find_child("SortieSplit", true, false) is HBoxContainer, "Sortie view is not split left-right")
	_assert_true(scene.find_child("CorePreview", true, false) != null, "Core preview is missing")
	_assert_true(scene.find_child("SortieControlsScroll", true, false) is ScrollContainer, "Sortie controls do not own a scroll surface")
	var slots := scene.find_children("CorePreviewSlot*", "Panel", true, false)
	_assert_true(slots.size() == 5, "Core preview must expose five exterior slots")


func _check_research_view(scene: Control) -> void:
	var tier_centers := scene.find_children("ResearchTierCenter*", "CenterContainer", true, false)
	var tier_grids := scene.find_children("ResearchTierGrid*", "GridContainer", true, false)
	var research_cards := scene.find_children("ResearchCard*", "Panel", true, false)
	_assert_true(tier_centers.size() == 5, "Research tiers are not centered")
	_assert_true(tier_grids.size() == 5, "Research tiers do not use fixed grids")
	_assert_true(research_cards.size() == 15, "Research cards are missing")
	for card: Panel in research_cards:
		_assert_true(is_equal_approx(card.custom_minimum_size.x, card.custom_minimum_size.y), "%s is not square" % card.name)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
