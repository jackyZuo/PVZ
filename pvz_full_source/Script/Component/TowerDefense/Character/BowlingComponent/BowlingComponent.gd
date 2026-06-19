
class_name BowlingComponent extends ComponentBase


signal bowling(character: TowerDefenseCharacter)

signal edgeRebound()


@onready var state: StateChart = %StateChart


@export var moveComponent: MoveComponent

@export var rollXVelocityMax: float = 250.0

@export var rollXVelocityMin: float = 200.0

@export var rollYVelocity: float = 250.0

@export var checkArea: Area2D

@export var hitEvent: Array[TowerDefenseCharacterEventBase]
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var rollAnimeClips: String = "Roll"

@export var rollAnimeTimeScale: float = 1.0
@export_subgroup("ExtendSetting")

@export var fallCoinUse: bool = true

@export var selfRotateUse: bool = false

@export var hitLineUse: bool = false:
    set(_hitLineUse):
        hitLineUse = _hitLineUse
        Refresh()

@export var hitLineBackUse: bool = false

@export var edgeReboundUse: bool = false:
    set(_edgeReboundUse):
        edgeReboundUse = _edgeReboundUse
        Refresh()


var parent: TowerDefenseCharacter


var hitNum: int = 0

var hitCharacter: TowerDefenseCharacter

var hitLineSave: int = -1


var hitLineCharacterList: Array[TowerDefenseCharacter]


var coinNum: int = 0


var isRoll: bool = false

var _sync_change_dir: int = 0
var _sync_deserializing: bool = false


func GetName() -> String:
    return "BowlingComponent"



func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
    if is_instance_valid(checkArea):
        if alive && parent.inGame && TowerDefenseManager.IsGameRunning():
            isRoll = true

        checkArea.area_entered.connect(HitCheck)
        await get_tree().physics_frame
        ChangeCheck()


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !isRoll:
        return
    if !edgeReboundUse:
        if global_position.x > TowerDefenseManager.GetMapGroundRight() + 300 || global_position.x < TowerDefenseManager.GetMapGroundLeft():
            parent.Destroy()
    else:
        if global_position.x > TowerDefenseManager.GetMapGroundRight():
            global_position.x = TowerDefenseManager.GetMapGroundRight()
            moveComponent.velocity.x = - moveComponent.velocity.x
            edgeRebound.emit()
            ChangeCheck()
            return
        if global_position.x < TowerDefenseManager.GetMapGroundLeft():
            global_position.x = TowerDefenseManager.GetMapGroundLeft()
            moveComponent.velocity.x = - moveComponent.velocity.x
            edgeRebound.emit()
            ChangeCheck()
            return


func Refresh() -> void :
    hitLineCharacterList.clear()
    hitCharacter = null
    hitLineSave = -1




func IdleEntered() -> void :
    pass


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !alive:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    state.send_event("ToRoll")


func IdleExited() -> void :
    pass


func RollEntered() -> void :
    isRoll = true
    ChangeCheck()
    AudioManager.AudioPlay("Bowling", AudioManagerEnum.TYPE.SFX)
    if sprite.HasClip(rollAnimeClips):
        sprite.SetAnimation(rollAnimeClips, true, 0.2)
    moveComponent.velocity.x = randf_range(rollXVelocityMin, rollXVelocityMax)


@warning_ignore("unused_parameter")
func RollProcessing(delta: float) -> void :
    if sprite.clip == rollAnimeClips:
        sprite.timeScale = rollAnimeTimeScale




    if selfRotateUse:
        sprite.rotate(moveComponent.velocity.x / 1000)
    var plantOffset: float = TowerDefenseManager.GetMapPlantOffset()
    var up: float = TowerDefenseManager.GetMapGroundUp()
    var down: float = TowerDefenseManager.GetMapGroundDown()
    if global_position.y < up + 50.0 * plantOffset / 50.0:
        hitLineSave = -1
        global_position.y = up + 50.0 * plantOffset / 50.0
        ChangeSpeed()
    if global_position.y > down - 20:
        hitLineSave = -1
        global_position.y = down - 20
        ChangeSpeed()


func RollExited() -> void :
    pass



func HitCheck(area: Area2D) -> void :
    if !isRoll:
        return
    var character = area.get_parent()
    if character is TowerDefenseCharacter:
        if !hitLineUse:
            if hitCharacter == character:
                return
        if !character.targetRegistrationComponent.canProjectileCheck:
            return
        if !character.instance.canBeCollection:
            return
        if parent.CanTarget(character) && parent.CanCollision(character.instance.maskFlags):
            if hitLineUse:
                if !hitLineBackUse:
                    if !hitLineCharacterList.has(character):
                        Bowling(character)
                        hitLineCharacterList.append(character)
                else:
                    Bowling(character)
            else:
                if hitLineSave != character.gridPos.y:
                    Bowling(character)



func Bowling(character: TowerDefenseCharacter) -> void :
    if !hitLineUse:
        hitLineSave = character.gridPos.y
    hitCharacter = character
    ChangeSpeed()
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if fallCoinUse:
        hitNum += 1
        if hitNum == 4:
            coinNum += 10
        if hitNum == 5:
            coinNum += 10
        if hitNum == 6:
            coinNum += 10
        if hitNum == 7:
            coinNum += 20
        if coinNum > 0:
            parent.CoinCreate(parent.global_position, coinNum, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0, false)
    AudioManager.AudioPlay("BowlingImpact", AudioManagerEnum.TYPE.SFX)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 2.0, 0.05, 4)
    for event: TowerDefenseCharacterEventBase in hitEvent:
        event.Execute(global_position, character)
    bowling.emit(character)


func ChangeSpeed() -> void :
    if hitLineUse:
        if hitLineBackUse:
            moveComponent.velocity.x = - moveComponent.velocity.x
        return
    var mapSize: Vector2 = TowerDefenseManager.GetMapGridNum()
    if hitLineSave == 1:
        moveComponent.velocity.y = rollYVelocity
        return
    if hitLineSave == mapSize.y:
        moveComponent.velocity.y = - rollYVelocity
        return
    if moveComponent.velocity.y != 0:
        moveComponent.velocity.y = - moveComponent.velocity.y
    else:
        if _sync_deserializing and _sync_change_dir != 0:
            moveComponent.velocity.y = rollYVelocity * _sync_change_dir
            _sync_deserializing = false
        elif randf() > 0.5:
            moveComponent.velocity.y = rollYVelocity
            _sync_change_dir = 1
        else:
            moveComponent.velocity.y = - rollYVelocity
            _sync_change_dir = -1


func ChangeCheck() -> void :
    for area in checkArea.get_overlapping_areas():
        HitCheck(area)

func ExportComponentSave() -> Dictionary:
    return {
        "isRoll": isRoll, 
        "hitNum": hitNum, 
        "hitLineSave": hitLineSave, 
        "coinNum": coinNum, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    isRoll = _data.get("isRoll", false)
    hitNum = _data.get("hitNum", 0)
    hitLineSave = _data.get("hitLineSave", -1)
    coinNum = _data.get("coinNum", 0)
    if isRoll && is_instance_valid(state):
        state.send_event("ToRoll")

func SyncSerialize() -> Dictionary:
    return {
        "isRoll": isRoll, 
        "hitNum": hitNum, 
        "hitLineSave": hitLineSave, 
        "coinNum": coinNum, 
        "change_dir": _sync_change_dir, 
        "velocity_x": moveComponent.velocity.x if is_instance_valid(moveComponent) else 0.0, 
        "velocity_y": moveComponent.velocity.y if is_instance_valid(moveComponent) else 0.0, 
        "edgeReboundUse": edgeReboundUse, 
        "hitLineUse": hitLineUse, 
        "hitLineBackUse": hitLineBackUse, 
        "rollXVelocityMax": rollXVelocityMax, 
        "rollXVelocityMin": rollXVelocityMin, 
        "alive": alive, 
    }

func SyncDeserialize(_data: Dictionary) -> void :
    isRoll = _data.get("isRoll", isRoll)
    hitNum = _data.get("hitNum", hitNum)
    hitLineSave = _data.get("hitLineSave", hitLineSave)
    coinNum = _data.get("coinNum", coinNum)
    _sync_change_dir = _data.get("change_dir", 0)
    _sync_deserializing = true
    edgeReboundUse = _data.get("edgeReboundUse", edgeReboundUse)
    hitLineUse = _data.get("hitLineUse", hitLineUse)
    hitLineBackUse = _data.get("hitLineBackUse", hitLineBackUse)
    rollXVelocityMax = _data.get("rollXVelocityMax", rollXVelocityMax)
    rollXVelocityMin = _data.get("rollXVelocityMin", rollXVelocityMin)
    alive = _data.get("alive", alive)
    if is_instance_valid(moveComponent):
        moveComponent.velocity.x = _data.get("velocity_x", moveComponent.velocity.x)
        moveComponent.velocity.y = _data.get("velocity_y", moveComponent.velocity.y)
    if isRoll && is_instance_valid(state):
        state.send_event("ToRoll")
