class_name DropItemConfig extends Resource

@export var id: ObjectManagerConfig.OBJECT = ObjectManagerConfig.OBJECT.NOONE
@export var name: StringName = ""
@export var scene: PackedScene
@export var poolMaxNum: int = 100
@export var category: TowerDefenseEnum.DROP_ITEM_CATEGORY = TowerDefenseEnum.DROP_ITEM_CATEGORY.NOONE
@export var value: int = 0
@export var fallAudio: String = "CoinFall"
@export var pickAudio: String = "CoinPick"
@export var coinObjectId: int = -1
@export var handler: DropItemHandler
