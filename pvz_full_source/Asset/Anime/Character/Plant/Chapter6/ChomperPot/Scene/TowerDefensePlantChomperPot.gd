@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var attackComponent2: AttackComponent = %AttackComponent2
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var chomperComponent: ChomperComponent = %ChomperComponent
@export var chewTime: float = 30.0:
    set(_chewTime):
        chewTime = _chewTime
        if !is_node_ready():
            await ready
        chomperComponent.chewTime = chewTime

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    checkShape.shape.size.x = TowerDefenseManager.GetMapGridSize().x * 1.25
    add_to_group("ChomperPot")

@warning_ignore("unused_parameter")
func ChewProcessing(delta: float) -> void :
    if attackComponent2.CanAttack():
        Teleport()

func Teleport() -> void :
    if attackComponent2.CanAttack():
        var targetList = attackComponent2.GetTargetList()
        if targetList.size() > 0:
            var chomperPotList = get_tree().get_nodes_in_group("ChomperPot").filter(
                func(checkCharacter: TowerDefenseCharacter):
                    return checkCharacter.chomperComponent.isChew
            )
            chomperPotList.erase(self)
            if chomperPotList.size() > 0:
                var chomperPot = chomperPotList.pick_random()
                for _target: TowerDefenseCharacter in targetList:
                    if _target.global_position.x < global_position.x - 10:
                        continue

                    var teleportOffset: float = - _target.scale.x * TowerDefenseManager.GetMapGridSize().x * 0.5
                    _target.shadowComponent.saveShadowPosition.y += chomperPot.global_position.y - _target.global_position.y
                    _target.global_position = chomperPot.global_position + Vector2(teleportOffset, 0)
                    _target.gridPos = chomperPot.gridPos


func ExportVariantSave() -> Dictionary:
    return {
        "chewTime": chewTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    chewTime = data.get("chewTime", 30.0)
