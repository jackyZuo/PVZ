@tool
extends TowerDefensePlant

@onready var chomperComponent: ChomperComponent = %ChomperComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    shadowComponent.shadowDisabled = false
    shadowSprite.visible = true
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 1.75

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        character.Hurt(min(50, num / 2), false)
