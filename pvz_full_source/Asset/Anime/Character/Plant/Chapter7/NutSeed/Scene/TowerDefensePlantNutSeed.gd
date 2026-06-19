@tool
extends TowerDefensePlant

const IMITATER_CLOUD = preload("uid://djvfnrjg7vtqn")

var over: bool = false
var isChange: bool = false
@export var changeTime: float = 50.0

var timer: float = 0.0

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !sprite.pause:
        if timer < changeTime:
            timer += delta * timeScale
        else:
            isChange = true
            Destroy()

func DestroySet() -> void :
    super.DestroySet()
    if over:
        return
    over = false
    if instance.hypnoses:
        BrainSunCreate(global_position, 25, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    else:
        SunCreate(global_position, 25, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    if isChange:
        await Change()

func Change() -> void :
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(IMITATER_CLOUD, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)
    await get_tree().physics_frame
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantNutFlower")
    packetConfig.Plant(gridPos)

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
        "isChange": isChange, 
        "timer": timer, 
        "changeTime": changeTime, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
    isChange = data.get("isChange", false)
    timer = data.get("timer", 0.0)
    changeTime = data.get("changeTime", 50.0)
