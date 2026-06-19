@tool
extends TowerDefensePlant

@onready var chomperComponent: ChomperComponent = %ChomperComponent
@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape

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
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 1.75
    instance.invincibleHurt = true

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        if character.instance.ArmorHas("SpecialHelmet"):
            SkipInvincibleHurt(num)
            return
    match type:
        "Eat":
            SkipInvincibleHurt(10)
            if is_instance_valid(character):
                character.Garlic()
        "Smash":
            Destroy()
        "Chomp":
            Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "chewTime": chewTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    chewTime = data.get("chewTime", 30.0)
