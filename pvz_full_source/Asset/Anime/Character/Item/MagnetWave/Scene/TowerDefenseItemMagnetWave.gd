@tool
extends TowerDefenseItem

@onready var magnetComponent: MagnetComponent = %MagnetComponent

var armorList: Array[TowerDefenseMagnet]

var over: bool = false
var drawNum: int = 1

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    HitBoxDestroy()

    await get_tree().physics_frame

    for i in drawNum:
        if await magnetComponent.CanArmorDraw():
            await magnetComponent.ArmorDrawNear()
            await get_tree().create_timer(0.1, false).timeout
            armorList.append(magnetComponent.magnet)
            magnetComponent.magnet = null
            magnetComponent.breakDownArmor = null

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    for magnet in armorList:
        if is_instance_valid(magnet):
            if magnet.global_position.distance_to(magnetComponent.posMarker.global_position) >= 0.01:
                magnet.global_position = lerp(magnet.global_position, magnetComponent.posMarker.global_position, 10.0 * delta)
                magnet.scale = lerp(magnet.scale, Vector2.ZERO, 10.0 * delta)

@warning_ignore("unused_parameter")
func Destroy(freeInsance: bool = true) -> void :
    magnetComponent.Destroy()
    super.Destroy(freeInsance)

func AnimeCompleted(clip: String) -> void :
    match clip:
        "Idle":
            Destroy()
