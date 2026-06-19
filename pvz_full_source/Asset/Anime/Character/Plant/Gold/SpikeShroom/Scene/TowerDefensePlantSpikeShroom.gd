@tool
extends TowerDefensePlant

const SPIKE_SHROOM_SKIN_3_1 = preload("uid://setqd0doysia")
const SPIKE_SHROOM_SKIN_3_2 = preload("uid://dtaq2xxqdn4l")
const SPIKE_SHROOM_SKIN_3_3 = preload("uid://d345b8j5t8rim")
const SPIKE_SHROOM_SKIN_4_1 = preload("uid://oupumw7ivoj2")
const SPIKE_SHROOM_SKIN_4_2 = preload("uid://blsvhscujc3wy")
const SPIKE_SHROOM_SKIN_4_3 = preload("uid://dab5sqapb1pxr")
const SPIKE_SHROOM_SKIN_6_1 = preload("uid://b4c2b841mg3hk")
const SPIKE_SHROOM_SKIN_6_2 = preload("uid://d3m54y244cyum")
const SPIKE_SHROOM_SKIN_6_3 = preload("uid://d35grguid2x18")

const SPIKE_SHROOM_ATTACK_EFFECT = preload("uid://b7rfl7fns2fe2")
const SPIKE_SHROOM_ATTACK_EFFECT_CUSTOM_0 = preload("uid://bac4csfsmibf0")

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var attackMarker: Marker2D = %AttackMarker

@export var fireInterval: float = 2.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("SpikeShroom_skin3_1.png", SPIKE_SHROOM_SKIN_3_1)
                sprite.SetReplace("SpikeShroom_skin4_1.png", SPIKE_SHROOM_SKIN_4_1)
                sprite.SetReplace("SpikeShroom_skin6_1.png", SPIKE_SHROOM_SKIN_6_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("SpikeShroom_skin3_1.png", SPIKE_SHROOM_SKIN_3_2)
                sprite.SetReplace("SpikeShroom_skin4_1.png", SPIKE_SHROOM_SKIN_4_2)
                sprite.SetReplace("SpikeShroom_skin6_1.png", SPIKE_SHROOM_SKIN_6_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("SpikeShroom_skin3_1.png", SPIKE_SHROOM_SKIN_3_3)
                sprite.SetReplace("SpikeShroom_skin4_1.png", SPIKE_SHROOM_SKIN_4_3)
                sprite.SetReplace("SpikeShroom_skin6_1.png", SPIKE_SHROOM_SKIN_6_3)

func Attack() -> void :
    AudioManager.AudioPlay("Spike", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackEventExecute()

    var effectScene: PackedScene = SPIKE_SHROOM_ATTACK_EFFECT
    if currentCustom.has("Custom0"):
        effectScene = SPIKE_SHROOM_ATTACK_EFFECT_CUSTOM_0
    var effect = TowerDefenseManager.CreateEffectSpriteOnce(effectScene, gridPos, "Idle")
    attackMarker.add_child(effect)

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character):
        if type != "Eat":
            character.Hurt(min(1000.0, num), false)
        else:
            character.Hurt(min(80, num / 3.0), false)

func ExportVariantSave() -> Dictionary:
    return {
        "fireInterval": fireInterval, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    fireInterval = data.get("fireInterval", 2.0)
