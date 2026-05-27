# Core Select Layout Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make core research cards read as centered square cells and keep a current core exterior preview visible beside sortie loadout controls.

**Architecture:** Keep the feature inside the existing dynamic `CoreSelectScene` UI builder. Add a headless layout contract script that checks named runtime containers, then reshape the research builder and sortie builder so the preview is assembled from existing `AbilityTreeNode.visual_slot` and `visual_variant` metadata without adding art assets or new saved state.

**Tech Stack:** Godot 4.6 GDScript, runtime `Control` nodes, project validation scripts.

---

## File Map

- Create `Scripts/Validation/check_core_select_layout.gd`: headless regression contract for dynamic CoreSelect research and sortie layout nodes.
- Modify `Scenes/CoreSelect/CoreSelectScene.gd`: square research card layout, sortie split layout, modular core exterior preview helpers.
- Modify `Scripts/Validation/validate.sh`: run the new CoreSelect contract with the existing Godot validation suite.
- Modify `Docs/WorkNote/2026-05-22.md`: implementation note and verification record for the UI work.
- Modify `Docs/TODO/TODO-NEXT.md`: mark the core layout task done when verification is complete.

### Task 1: Add The Failing CoreSelect Layout Contract

**Files:**
- Create: `Scripts/Validation/check_core_select_layout.gd`

- [ ] **Step 1: Write the failing layout contract**

```gdscript
extends SceneTree

const CORE_SELECT_SCENE: PackedScene = preload("res://Scenes/CoreSelect/CoreSelectScene.tscn")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := CORE_SELECT_SCENE.instantiate() as Control
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
```

- [ ] **Step 2: Run the new contract and confirm it fails for missing layout names**

Run:

```powershell
& 'C:\Users\theoe\gameDev\Godot_v4.6.2-stable_win64.exe' --headless --path . --script res://Scripts/Validation/check_core_select_layout.gd
```

Expected: exit nonzero with failures for `SortieSplit`, `CorePreview`, `SortieControlsScroll`, and research square-grid nodes.

### Task 2: Center Square Research Cells

**Files:**
- Modify: `Scenes/CoreSelect/CoreSelectScene.gd`

- [ ] **Step 1: Add research card sizing constants**

```gdscript
const RESEARCH_CARD_SIZE: float = 268.0
const RESEARCH_GRID_SEPARATION: int = 10
```

- [ ] **Step 2: Replace the research row builder with centered three-column grids**

```gdscript
func _show_research_view() -> void:
	_clear_view()
	_refresh_meta_label()
	_view_host.add_child(_make_note("잠긴 노드도 효과 축을 확인할 수 있다. 이전 티어에서 하나라도 구매하면 다음 티어 연구가 열린다."))
	for tier: int in range(1, 6):
		_view_host.add_child(_make_section_label("T%d 연구" % tier))
		var center := CenterContainer.new()
		center.name = "ResearchTierCenter%d" % tier
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var grid := GridContainer.new()
		grid.name = "ResearchTierGrid%d" % tier
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", RESEARCH_GRID_SEPARATION)
		grid.add_theme_constant_override("v_separation", RESEARCH_GRID_SEPARATION)
		for node: AbilityTreeNode in _nodes_for_tier(tier):
			grid.add_child(_make_research_card(node))
		center.add_child(grid)
		_view_host.add_child(center)
```

- [ ] **Step 3: Make each research card square and test-addressable**

```gdscript
func _make_research_card(node: AbilityTreeNode) -> Panel:
	var panel := _make_card_panel(Vector2(RESEARCH_CARD_SIZE, RESEARCH_CARD_SIZE), TRACK_COLORS[node.track])
	panel.name = "ResearchCard_%s" % node.node_id
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	body.add_child(_make_card_title("%s [%s]" % [node.display_name, TRACK_LABELS[node.track]]))
	body.add_child(_make_wrapped_label(node.description, 11))
	body.add_child(_make_wrapped_label("외장: %s / %s" % [node.visual_slot, node.visual_variant], 10))
	body.add_child(_make_wrapped_label(node.level_five_bonus_text, 10))

	var level: int = GameState.get_tree_node_level(node.node_id)
	var status := Label.new()
	status.text = "레벨 %d / 5" % level if level > 0 else "잠김 - 연구 비용 %d" % node.research_cost
	status.add_theme_font_size_override("font_size", 11)
	body.add_child(status)

	var action := Button.new()
	if level <= 0:
		action.text = "연구"
		action.disabled = not _can_research_node(node)
		action.pressed.connect(_on_research_pressed.bind(node))
	elif level < 5:
		action.text = "레벨업 %d" % node.level_cost(level + 1)
		action.disabled = GameState.meta_credits < node.level_cost(level + 1)
		action.pressed.connect(_on_level_pressed.bind(node))
	else:
		action.text = "최대 레벨"
		action.disabled = true
	body.add_child(action)
	return panel
```

- [ ] **Step 4: Re-run the CoreSelect layout contract**

Run:

```powershell
& 'C:\Users\theoe\gameDev\Godot_v4.6.2-stable_win64.exe' --headless --path . --script res://Scripts/Validation/check_core_select_layout.gd
```

Expected: the research assertions pass while sortie split assertions still fail.

### Task 3: Split Sortie View And Render Core Exterior Preview

**Files:**
- Modify: `Scenes/CoreSelect/CoreSelectScene.gd`

- [ ] **Step 1: Add preview labels and size constants**

```gdscript
const SORTIE_PREVIEW_WIDTH: float = 316.0
const SORTIE_CONTROLS_WIDTH: float = 620.0
const CORE_PREVIEW_SLOT_LABELS: Dictionary = {
	"top_cover": "상판 덮개",
	"front_hood": "전면 후드",
	"side_armor": "측면 장갑",
	"rear_pack": "후방 팩",
	"core_spine": "코어 스파인",
}
```

- [ ] **Step 2: Build the sortie view as a named left-right split**

```gdscript
func _show_sortie_view() -> void:
	_clear_view()
	_refresh_meta_label()

	var split := HBoxContainer.new()
	split.name = "SortieSplit"
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 14)
	split.add_child(_make_core_preview())

	var controls_scroll := ScrollContainer.new()
	controls_scroll.name = "SortieControlsScroll"
	controls_scroll.custom_minimum_size = Vector2(SORTIE_CONTROLS_WIDTH, 500.0)
	controls_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_scroll.add_child(_make_sortie_controls())
	split.add_child(controls_scroll)
	_view_host.add_child(split)
```

- [ ] **Step 3: Move existing sortie controls into a reusable builder**

```gdscript
func _make_sortie_controls() -> VBoxContainer:
	var controls := VBoxContainer.new()
	controls.name = "SortieControls"
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 12)
	controls.add_child(_make_dungeon_intel())
	controls.add_child(_make_section_label("기본 공격 택 1"))
	controls.add_child(_make_skill_choice_row(_basic_attacks, true))
	controls.add_child(_make_section_label("어빌리티 트리 로드아웃"))
	for tier: int in range(1, 6):
		controls.add_child(_make_sortie_tier_row(tier))
	controls.add_child(_make_section_label("파츠 활용 어빌리티 택 1"))
	controls.add_child(_make_skill_choice_row(_part_abilities, false))
	controls.add_child(_make_loadout_preview())

	var start_button := Button.new()
	start_button.text = "출격"
	start_button.custom_minimum_size = Vector2(220.0, 44.0)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_sortie_pressed)
	controls.add_child(start_button)
	return controls
```

- [ ] **Step 4: Add the modular preview builder that always shows five exterior slots**

```gdscript
func _make_core_preview() -> Panel:
	var panel := _make_card_panel(Vector2(SORTIE_PREVIEW_WIDTH, 500.0), Color(0.10, 0.14, 0.18))
	panel.name = "CorePreview"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	body.add_child(_make_card_title("현재 코어 외형"))
	body.add_child(_make_wrapped_label("이번 출격에 장착한 티어 외장을 기준으로 표시한다.", 11))

	var frame := GridContainer.new()
	frame.columns = 1
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_constant_override("v_separation", 8)
	for tier: int in range(1, 6):
		frame.add_child(_make_core_preview_slot(tier))
	body.add_child(frame)
	body.add_child(_make_wrapped_label(_stat_preview_text(), 11))
	return panel


func _make_core_preview_slot(tier: int) -> Panel:
	var node: AbilityTreeNode = _selected_node_for_tier(tier)
	var color: Color = Color(0.20, 0.23, 0.28) if node == null else TRACK_COLORS[node.track]
	var slot := _make_card_panel(Vector2(0.0, 62.0), color)
	slot.name = "CorePreviewSlot%d" % tier
	var body: VBoxContainer = slot.get_child(0) as VBoxContainer
	var slot_name: String = "비어 있는 외장"
	var variant_text: String = "티어 노드 미장착"
	if node != null:
		slot_name = str(CORE_PREVIEW_SLOT_LABELS.get(node.visual_slot, node.visual_slot))
		variant_text = "%s [%s] / %s" % [node.display_name, TRACK_LABELS[node.track], node.visual_variant]
	body.add_child(_make_card_title("T%d %s" % [tier, slot_name]))
	body.add_child(_make_wrapped_label(variant_text, 10))
	return slot
```

- [ ] **Step 5: Re-run the CoreSelect layout contract**

Run:

```powershell
& 'C:\Users\theoe\gameDev\Godot_v4.6.2-stable_win64.exe' --headless --path . --script res://Scripts/Validation/check_core_select_layout.gd
```

Expected: `CoreSelect layout: PASS`.

### Task 4: Wire Validation And Record The Work

**Files:**
- Modify: `Scripts/Validation/validate.sh`
- Modify: `Docs/WorkNote/2026-05-22.md`
- Modify: `Docs/TODO/TODO-NEXT.md`

- [ ] **Step 1: Add the CoreSelect contract to the validation suite**

```bash
run_check "CoreSelect layout" run_godot_script res://Scripts/Validation/check_core_select_layout.gd
```

Place it after the existing scene smoke validation and before P0 combat flows.

- [ ] **Step 2: Record the implementation note**

Append this WorkNote section:

```markdown
### [feat] 코어 설계 정사각 셀 및 출격 외형 프리뷰 구현

- 코어 연구 티어 행을 가운데 정렬된 정사각형 노드 셀 그리드로 바꿔 셀 폭·높이 흔들림을 제거.
- 출격 준비 보기를 좌우 분할하고 왼쪽에 선택한 티어 외장 슬롯을 읽는 현재 코어 프리뷰를 추가.
- `check_core_select_layout.gd` headless 검증으로 정사각 연구 셀, 출격 분할, 다섯 외장 슬롯 계약을 고정.
- 참조한 문서: [[AbilityTreeSystem]], [[UI/HUD]], [[superpowers/specs/2026-05-22-core-select-layout-preview-design]]
- 변경된 파일: `Scenes/CoreSelect/CoreSelectScene.gd`, `Scripts/Validation/check_core_select_layout.gd`, `Scripts/Validation/validate.sh`
```

- [ ] **Step 3: Mark the TODO item complete**

```markdown
- [x] **코어 설계 화면 레이아웃 정리** — 연구 노드 셀 정사각형 중심 정렬, 출격 준비 좌우 분할, 선택 외장 기반 코어 프리뷰 구현. (2026-05-22) [[Docs/superpowers/specs/2026-05-22-core-select-layout-preview-design]]
```

- [ ] **Step 4: Run full validation**

Run:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' --login -lc 'bash Scripts/Validation/validate.sh'
```

Expected: `Validation complete: PASS`; `gdparse` may report `SKIP` if not installed.

- [ ] **Step 5: Review diff hygiene**

Run:

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors; only the planned scene, validation, docs, and plan files are modified.
