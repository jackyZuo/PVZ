class_name TowerDefenseBattleFeatureHammer extends TowerDefenseBattleFeature

const TOWER_DEFENSE_HAMMER_MODE = preload("uid://bg3jr7ygc5lkf")

var hammerModeNode: Node2D

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    hammerModeNode = TOWER_DEFENSE_HAMMER_MODE.instantiate()
    control.characterNode.get_parent().add_child(hammerModeNode)

func GameFail() -> void :
    Destroy()

func Destroy() -> void :
    if is_instance_valid(hammerModeNode):
        hammerModeNode.queue_free()
        hammerModeNode = null

func SaveFeature() -> Dictionary:
    return {"hammer": true}

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    pass
