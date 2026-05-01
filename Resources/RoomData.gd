# 방 1개의 데이터를 정의
extends Resource

class_name RoomData

enum RoomType { BATTLE_NORMAL, BATTLE_ELITE, CHEST, ENCOUNTER, WORKSHOP, BOSS }
enum RewardGrade { NONE, COMMON, RARE, EPIC }

@export var room_type: RoomType = RoomType.BATTLE_NORMAL
@export var hint: String = "" # 다음 방 미리 공개 텍스트

@export var reward_grade: RewardGrade = RewardGrade.NONE