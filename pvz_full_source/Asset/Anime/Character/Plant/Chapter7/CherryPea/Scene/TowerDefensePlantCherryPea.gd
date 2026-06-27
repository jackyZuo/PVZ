@tool
extends TowerDefensePlant

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent
const TOWER_DEFENSE_PROJECTILE_EFFECT_CHERRY_PEA = preload("uid://c4cl6w0kg0pup")
const PEA_BOMB_S_EXPLOSION = preload("uid://esp31duw2h25")

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if currentCustom.has("Custom0"):
        explodeComponent.explodeEffect = PEA_BOMB_S_EXPLOSION

func Explode() -> void :
    var projectileEffect = TOWER_DEFENSE_PROJECTILE_EFFECT_CHERRY_PEA.instantiate()
    projectileEffect.Init(gridPos, camp, config.collisionFlags, null, groundHeight)
    projectileEffect.global_position = global_position
    characterNode.add_child(projectileEffect)
