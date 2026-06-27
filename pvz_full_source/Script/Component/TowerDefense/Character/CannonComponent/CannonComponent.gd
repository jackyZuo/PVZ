
class_name CannonComponent extends ComponentBase


signal fire()

signal rest()

signal charge()


@onready var timerComponent: TimerComponent = %TimerComponent

@onready var state: StateChart = %StateChart


@export_enum("Marker", "Line") var mode: String = "Marker"

@export var mousePressComponent: MousePressComponent

@export var projectileSlot: AdobeAnimateSlot

@export var projectileNode: Node2D

@export var projectileData: TowerDefenseProjectileCreateData


var projectileName: String:
    get:
        if projectileData:
            return String(projectileData.projectileName)
        return ""


@export var projectileLineFireComponent: FireComponent

@export var projectileLineMarker: Marker2D

@export var autoAttack: bool = false

@export_subgroup("Setting")

@export var restTime: float = 30

@export var firstRestTime: float = 3.0
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var fireReadyEventName: String = "fire_ready"

@export var fireEventName: String = "fire"

@export var restAnimeClips: String = "Rest"

@export var restAnimeTimeScale: float = 1.0

@export var chargeAnimeClips: String = "Charge"

@export var chargeAnimeTimeScale: float = 1.0

@export var fireAnimeClips: String = "Fire"

@export var fireAnimeTimeScale: float = 1.0


var parent: TowerDefenseCharacter


var canFire: bool = false:
    set(_canFire):
        canFire = _canFire
        if is_instance_valid(mousePressComponent):
            if canFire:
                mousePressComponent.alive = true
            else:
                mousePressComponent.alive = false


var targetPos: Vector2 = Vector2.ZERO


var _restTimerPaused: bool = false


func GetName() -> String:
    return "CannonComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    if is_instance_valid(mousePressComponent):
        match mode:
            "Marker":
                mousePressComponent.finishPressed.connect(Fire)
            "Line":
                mousePressComponent.pressed.connect(Fire)
        mousePressComponent.alive = false
    if is_instance_valid(projectileNode):
        projectileNode.visible = false
    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        sprite.animeEvent.connect(AnimeEvent)
    await get_tree().physics_frame
    timerComponent.Run("Rest", firstRestTime)
    state.send_event("ToRest")
    parent.Component()
    canFire = false


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return
    if !parent.inGame:
        if timerComponent.IsRunning("Rest"):
            timerComponent.Stop("Rest")
            _restTimerPaused = true
        return
    if _restTimerPaused:
        _restTimerPaused = false
        timerComponent.Run("Rest", restTime)
    if autoAttack:
        if canFire:
            canFire = false
            var characterList = TowerDefenseManager.GetCampTarget(parent.camp)
            var groundRight: float = TowerDefenseManager.GetMapGroundRight()
            characterList = characterList.filter( func(character: TowerDefenseCharacter):
                return character.instance.canBeCollection && !character.instance.invincible && character.global_position.x <= groundRight
            )
            if characterList.size() > 0:
                Fire(characterList.pick_random().global_position)





func Fire(pos: Vector2) -> void :
    parent.componentChange.emit()
    fire.emit()
    canFire = false
    targetPos = pos
    if parent is not TowerDefenseZombie:
        parent.Component()
    state.send_event("ToFire")


func Canfire() -> bool:
    return canFire


func IdleEntered() -> void :
    if !parent.inGame:
        return
    if parent.instance.sleep:
        return
    if !parent.componentAlive:
        return
    if timerComponent.IsRunning("Rest"):
        state.send_event("ToRest")
        parent.Component()
        return
    if !TowerDefenseManager.IsGameRunning() || parent is not TowerDefenseZombie:
        parent.Idle()
    canFire = true


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if parent.instance.sleep || !parent.componentAlive:
        canFire = false
    else:
        canFire = true


func IdleExited() -> void :
    pass


func RestEntered() -> void :
    rest.emit()
    if is_instance_valid(sprite):
        sprite.SetAnimation(restAnimeClips, true, 0.2)


@warning_ignore("unused_parameter")
func RestProcessing(delta: float) -> void :
    if !is_instance_valid(sprite):
        return
    if !TowerDefenseManager.IsIZMMode():
        if !is_instance_valid(parent):
            return
        sprite.timeScale = parent.timeScale * restAnimeTimeScale
    else:
        sprite.timeScale = restAnimeTimeScale


func RestExited() -> void :
    pass


func ChargeEntered() -> void :
    charge.emit()
    canFire = true
    if is_instance_valid(sprite):
        sprite.SetAnimation(chargeAnimeClips, false, 0.2)
    AudioManager.AudioPlay("Shoop", AudioManagerEnum.TYPE.SFX)


@warning_ignore("unused_parameter")
func ChargeProcessing(delta: float) -> void :
    if !is_instance_valid(sprite):
        return
    if !TowerDefenseManager.IsIZMMode():
        if !is_instance_valid(parent):
            return
        sprite.timeScale = parent.timeScale * chargeAnimeTimeScale
    else:
        sprite.timeScale = chargeAnimeTimeScale


func ChargeExited() -> void :
    pass


func FireEntered() -> void :
    if is_instance_valid(sprite):
        sprite.SetAnimation(fireAnimeClips, false, 0.2)


func _fire_marker_projectile() -> void :
    var _gridPos = TowerDefenseManager.GetMapGridPosFromMouse(targetPos)
    var _cell = TowerDefenseManager.GetMapCell(_gridPos)
    targetPos.y = TowerDefenseManager.GetMapCellPosCenter(_gridPos).y + 20
    var height = 0
    if is_instance_valid(_cell):
        height = - _cell.GetGroundHeight()
    var projectile: TowerDefenseProjectile = FireComponent.CreateProjectilePosition(null, null, height, targetPos, Vector2.ZERO, projectileData, -1, parent.camp)
    projectile.hitBox.scale = Vector2(2.0, 1.0)
    projectile.gridPos = _gridPos
    projectile.z = 600
    projectile.ySpeed = 800
    projectile.useFall = true


@warning_ignore("unused_parameter")
func FireProcessing(delta: float) -> void :
    if !is_instance_valid(sprite):
        return
    if !TowerDefenseManager.IsIZMMode():
        if !is_instance_valid(parent):
            return
        sprite.timeScale = parent.timeScale * fireAnimeTimeScale
    else:
        sprite.timeScale = fireAnimeTimeScale


func FireExited() -> void :
    pass



func AnimeCompleted(clip: String) -> void :
    match clip:
        chargeAnimeClips:
            state.send_event("ToIdle")
        fireAnimeClips:
            timerComponent.Run("Rest", restTime)
            state.send_event("ToRest")




@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    match command:
        fireReadyEventName:
            AudioManager.AudioPlay("CobLaunch", AudioManagerEnum.TYPE.SFX)
        fireEventName:
            match mode:
                "Marker":
                    if is_instance_valid(projectileSlot):
                        projectileSlot.Update()
                        if is_instance_valid(projectileNode):
                            projectileNode.visible = true
                            projectileNode.global_transform = projectileSlot.global_transform
                            var tween = create_tween()
                            tween.tween_property(projectileNode, ^"global_position:y", global_position.y - 600, 0.75)
                            tween.tween_callback( func():
                                if is_instance_valid(projectileNode):
                                    projectileNode.visible = false
                                _fire_marker_projectile()
                            )
                        else:
                            _fire_marker_projectile()
                    else:
                        _fire_marker_projectile()
                "Line":
                    var projectile = projectileLineFireComponent.CreateProjectile(0, Vector2(800, 0), projectileData, -1, parent.camp, Vector2.ZERO)
                    projectile.projectileBodyNode.scale.x = parent.scale.x
                    projectile.gridPos = parent.gridPos



func Timeout(timerName: String) -> void :
    match timerName:
        "Rest":
            state.send_event("ToCharge")

func ExportComponentSave() -> Dictionary:
    return {
        "canFire": canFire, 
        "targetPosX": targetPos.x, 
        "targetPosY": targetPos.y, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    canFire = _data.get("canFire", true)
    targetPos = Vector2(_data.get("targetPosX", 0.0), _data.get("targetPosY", 0.0))

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "canFire": canFire, 
        "targetPosX": targetPos.x, 
        "targetPosY": targetPos.y, 
    }
    if is_instance_valid(state) and is_instance_valid(state._state) and state._state is CompoundState and is_instance_valid(state._state._active_state):
        data["state"] = state._state._active_state.name
    return data

func SyncDeserialize(data: Dictionary) -> void :
    canFire = data.get("canFire", false)
    targetPos = Vector2(data.get("targetPosX", 0.0), data.get("targetPosY", 0.0))
    if data.has("state"):
        _sync_force_state(data["state"])

func _sync_force_state(target_state: String) -> void :
    if !is_instance_valid(state) or !is_instance_valid(state._state):
        return
    if !(state._state is CompoundState) or !is_instance_valid(state._state._active_state):
        return
    if state._state._active_state.name == target_state:
        return
    state.send_event("To" + target_state)
