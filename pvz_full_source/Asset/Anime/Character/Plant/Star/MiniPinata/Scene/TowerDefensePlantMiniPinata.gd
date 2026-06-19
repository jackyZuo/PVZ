@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var collisionShape: CollisionShape2D = %CollisionShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75


func Explode() -> void :
    var targetList = attackComponent.GetTargetList()
    for target: TowerDefenseCharacter in targetList:
        if target is not TowerDefenseZombie:
            continue
        if target.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            continue
        if target.instance.hypnoses:
            continue
        if target.transformPoint.scale.x > 0.25:
            var tween = target.create_tween()
            tween.set_ease(Tween.EASE_IN)
            tween.set_trans(Tween.TRANS_BACK)
            tween.tween_property(target.transformPoint, ^"scale", target.transformPoint.scale * 0.5, 1.0)
            target.instance.hitpointScale *= 0.5
        target.instance.ArmorClear()
