@tool
class_name TowerDefenseMower extends TowerDefenseItem

const MOWER_SPAWN = preload("uid://dy8bwagg440x0")

@export var runAnimeClips: String = "Normal"
@export var runWaterAnimeClips: String = "Normal"
@export var attackAnimeClips: String = ""
@export var attackWaterAnimeClips: String = ""
var moveComponent: MoveComponent
var mowerHitComponent: MowerHitComponent

var run: bool = false

signal running(mower: TowerDefenseMower)

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        moveComponent = componentManager.GetComponentFromType("MoveComponent")
        mowerHitComponent = componentManager.GetComponentFromType("MowerHitComponent")
    var spawnEffect = TowerDefenseManager.CreateEffectSpriteOnce(MOWER_SPAWN, gridPos)
    spawnEffect.global_position = global_position
    characterNode.add_child(spawnEffect)
    sprite.pause = true
    instance.invincible = true
    add_to_group("Mower", true)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if run:
        var mapFeature: TowerDefenseBattleFeatureMap = TowerDefenseManager.GetMapFeature()
        var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
        if global_position.x > mapFeature.config.edge.z:
            Destroy()
        if TowerDefenseManager.IsIZM2Mode():
            if global_position.x > TowerDefenseManager.GetMapCellPos(Vector2i(floor(float(TowerDefenseManager.GetMapGridNum().x) / 3) + 1, 0)).x:
                TowerDefenseManager.CreateMower(gridPos.y)
                var spawnEffect = TowerDefenseManager.CreateEffectSpriteOnce(MOWER_SPAWN, gridPos)
                spawnEffect.global_position = global_position
                characterNode.add_child(spawnEffect)
                Destroy()
        if TowerDefenseManager.GetMapFeature():
            if is_instance_valid(cell):
                var cellPos: Vector2 = TowerDefenseManager.GetMapCellPos(gridPos)

                var offset: Vector2 = global_position - cellPos
                cellPercentage = offset.x / gridSize.x
                inWater = cell.IsWater()
            else:
                inWater = false

    if !inWater:
        if is_instance_valid(cell):
            var targetHeight: float = cell.GetGroundHeight(cellPercentage)
            if abs(groundHeight - targetHeight) > 0.1:
                groundHeight = lerpf(groundHeight, targetHeight, 3.0 * delta)
            else:
                groundHeight = targetHeight


func RunEntered() -> void :
    running.emit(self)
    moveComponent.SetVelocity(Vector2.RIGHT * 200.0)
    sprite.pause = false
    AudioManager.AudioPlay("Mower", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Normal", true)

@warning_ignore("unused_parameter")
func RunProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 3.0
    if CanSleep():
        Sleep()

func RunExited() -> void :
    pass

func HitCheck(area: Area2D) -> void :
    mowerHitComponent.HitCheck(area)

func Hit(character: TowerDefenseCharacter) -> void :
    mowerHitComponent.Hit(character)

func Run() -> void :
    state.send_event("ToRun")

func InWater() -> void :
    super.InWater()
    if runWaterAnimeClips != "":
        sprite.SetAnimation(runWaterAnimeClips, true, 0.1)

func OutWater() -> void :
    super.OutWater()
    if runAnimeClips != "":
        sprite.SetAnimation(runAnimeClips, true, 0.1)

@warning_ignore("unused_parameter")
func BlowBack(num: float, time: float = 1.0) -> void :
    pass
