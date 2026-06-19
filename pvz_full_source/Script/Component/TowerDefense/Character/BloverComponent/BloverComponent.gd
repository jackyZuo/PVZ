
class_name BloverComponent extends ComponentBase


@export var blowTime: float = 2.0

@export var blowLength: float = 0.5

@export var blowPhysiqueHugeLength: float = 0.5

@export var blowAirCharacterLength: float = 0.5

@export var blowAirCharacterOut: bool = true

@export var checkLine: bool = false

@export var checkCollision: bool = false

@export var checkPhysiqueHuge: bool = false
@export_subgroup("Projectile")

@export var projectileRowNum: int = 20

@export var projectileDataList: Array[TowerDefenseProjectileCreateData] = []
@export_subgroup("Event")

@export var eventList: Array[TowerDefenseCharacterEventBase] = []


signal blowOver()


var parent: TowerDefenseCharacter

var projectileConfigList: Array[TowerDefenseProjectileConfig] = []

var _sync_projectile_data: Array = []
var _sync_deserializing: bool = false


func GetName() -> String:
    return "BloverComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    for data: TowerDefenseProjectileCreateData in projectileDataList:
        projectileConfigList.append(data.BuildConfig())


func Execult() -> void :
    BattleEventBus.blowAllEffectEmit.emit()
    ExecuteTargetList(TowerDefenseManager.GetCharacterTarget(parent, checkLine, checkCollision))



func ExecuteLine(line: int) -> void :
    BattleEventBus.blowLineEffectEmit.emit(line)
    ExecuteTargetList(TowerDefenseManager.GetCharacterTargetLine(parent))



func ExecuteTargetList(targetList: Array) -> void :
    AudioManager.AudioPlay("Blover", AudioManagerEnum.TYPE.SFX)
    for target: TowerDefenseCharacter in targetList:
        if !checkPhysiqueHuge && target is TowerDefenseZombie:
            if target.instance.zombiePhysique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
                if !(target.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                    continue
        if target is TowerDefensePlant || target is TowerDefenseGravestone || target is TowerDefenseItem:
            continue
        if target.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_GROUND:
            continue
        if target.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER:
            continue
        for event: TowerDefenseCharacterEventBase in eventList:
            event.Execute(target.global_position, target)
        if target.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.BLOW:
            continue
        if target.instance.maskFlags == 0:
            continue
        var bloweLengthGet: float = - blowLength if parent.instance.hypnoses else blowLength
        if target.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
            if blowAirCharacterOut:
                target.Blow()
                continue
            bloweLengthGet = blowAirCharacterLength

        if target is TowerDefenseZombie:
            if target.instance.zombiePhysique >= TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
                if !(target.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                    bloweLengthGet = blowPhysiqueHugeLength
        target.BlowBack(bloweLengthGet, blowTime)
    if !projectileConfigList.is_empty():
        var height: float = parent.GetGroundHeight(parent.global_position.y)
        _sync_projectile_data.clear()
        for id in range(projectileRowNum):
            for line in range(1, TowerDefenseManager.GetMapGridNum().y + 1):
                var pos: Vector2 = Vector2(-50, TowerDefenseManager.GetMapCellPlantPos(Vector2(0, line)).y)
                if parent.instance.hypnoses:
                    pos.x = TowerDefenseManager.GetMapGroundRight()
                var heightOffset: float = randf_range(-10, 40) + 20
                var pickedConfig: TowerDefenseProjectileConfig = projectileConfigList.pick_random()
                var projVelocityX: float = randf_range(400.0, 800.0) * (-1 if parent.instance.hypnoses else 1)
                _sync_projectile_data.append({
                    "line": line, 
                    "height_offset": heightOffset, 
                    "velocity_x": projVelocityX, 
                    "config_index": projectileConfigList.find(pickedConfig)
                })
                var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePositionByConfig(null, null, height + heightOffset, pos + Vector2(0, 20), Vector2(projVelocityX, 0.0), pickedConfig, -1, parent.camp)
                projectile.projectileBodyNode.scale.x = parent.global_scale.x
                projectile.gridPos.y = line
            await get_tree().create_timer(0.1, false).timeout
    else:
        await get_tree().create_timer(blowTime, false).timeout
    blowOver.emit()

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {}
    if !_sync_projectile_data.is_empty():
        data["projectile_data"] = _sync_projectile_data
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("projectile_data"):
        _sync_projectile_data = _data["projectile_data"]
        _sync_deserializing = true
