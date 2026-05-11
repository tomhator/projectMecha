# 런 메타 정보
extends Node

# --- 런 메타 정보 ---
var is_run_active: bool = false
var current_floor: int = 0
var current_core: CoreData = null

# --- 메카 런타임 상태 ---
var current_hp: float = 0.0
var current_shield: float = 0.0
var current_payload: float = 0.0
var current_action_count: int = 0

# 부품 장착 상태
# key: CoreData.CoreSlot, value: PartsData (null이면 빈 슬롯)
var equipped_parts: Dictionary = {
	CoreData.CoreSlot.ARM_L: null,
	CoreData.CoreSlot.ARM_R: null,
	CoreData.CoreSlot.BACK: null,
	CoreData.CoreSlot.LEG: null
}

# 인벤토리 상태
# 부품 데이터 배열
var inventory: Array[PartsData] = []

# 재화
var credits: int = 0

# 공격 배율
var attack_multiplier: float = 1.0

# -----------------------------------


func start_run(core: CoreData) -> void:
	is_run_active = true
	current_floor = 1
	current_core = core
	EventBus.floor_changed.emit(current_floor)
	current_hp = current_core.core_hp
	current_shield = current_core.core_shield
	current_payload = 0.0 # 시작 시 장착된 부품 없음
	current_action_count = current_core.core_action_count
	attack_multiplier = current_core.core_attack_multiplier
	equipped_parts = {
		CoreData.CoreSlot.ARM_L: null,
		CoreData.CoreSlot.ARM_R: null,
		CoreData.CoreSlot.BACK: null,
		CoreData.CoreSlot.LEG: null
	}
	credits = 0
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)
	inventory = []

func end_run() -> void:
	is_run_active = false

func advance_floor() -> void:
	current_floor += 1
	EventBus.floor_changed.emit(current_floor)

# 부품 장착/해제
func equip_part(part: PartsData, slot: CoreData.CoreSlot) -> void:
	var prev: PartsData = equipped_parts[slot]
	if prev != null:
		current_payload -= prev.parts_weight
	equipped_parts[slot] = part
	current_payload += part.parts_weight
	EventBus.parts_equipped.emit(part, slot)
	EventBus.payload_changed.emit(self, current_payload, current_core.core_max_payload)

func unequip_part(slot: CoreData.CoreSlot) -> void:
	var prev: PartsData = equipped_parts[slot]
	if prev != null:
		current_payload -= prev.parts_weight
	equipped_parts[slot] = null
	EventBus.parts_unequipped.emit(prev, slot)
	EventBus.payload_changed.emit(self, current_payload, current_core.core_max_payload)

# 재화 추가/차감
func add_credits(amount: int) -> void:
	credits += amount
	EventBus.credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	EventBus.credits_changed.emit(credits)
	return true

# HP/Shield
func take_damage(amount: float) -> void:
	var absorbed: float = minf(current_shield, amount) # 방어력 적용
	current_shield -= absorbed
	current_hp -= amount - absorbed # 피해 적용
	current_hp = maxf(current_hp, 0.0) # HP가 0 이하가 되지 않도록 함
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)

func heal_hp(amount: float) -> void:
	current_hp = minf(current_hp + amount, current_core.core_hp)
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)

func heal_shield(amount: float) -> void:
	current_shield = minf(current_shield + amount, current_core.core_shield)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)

# 인벤토리 관리
func add_to_inventory(part: PartsData) -> void:
	inventory.append(part)
	EventBus.inventory_changed.emit(inventory)