
class_name ChomperComponent extends ComponentBase


signal biteStart()

signal biteFail()

signal chewProcessing(delta)

signal chewBegin()

signal chewOver()

signal swallowOver()


@onready var state: StateChart = %StateChart


var parent: TowerDefenseCharacter


@export var attackComponent: AttackComponent

@export var chewTime: float = 30.0

@export var biteAttack: float = -1

@export var biteEvent: Array[TowerDefenseCharacterEventBase]

@export var biteOnly: bool = false

@export var biteNoLimit: bool = false
@export_subgroup("AnimeSetting")

@export var sprite: AdobeAnimateSprite

@export var biteEventName: String = "attack"

@export var biteStartAnimeClips: String = "Bite"

@export var biteStartAnimeTimeScale: float = 1.5

@export var biteLoopAnimeClips: String = "BiteLoop"

@export var biteLoopAnimeTimeScale: float = 1.5

@export var biteEndAnimeClips: String = "BiteEnd"

@export var biteEndAnimeTimeScale: float = 1.5

@export var chewReadyAnimeClips: String = ""

@export var chewReadyAnimeTimeScale: float = 1.0

@export var chewAnimeClips: String = "Chew"

@export var chewAnimeTimeScale: float = 1.0

@export var swallowAnimeClips: String = "Swallow"

@export var swallowAnimeTimeScale: float = 1.0

@export var isPartSprite: bool = false

@export var partIdleAnimeClips: String = "Idle"

@export var partIdleAnimeTimeScale: float = 1.5
@export_subgroup("SuckSetting")

@export var suckUse: bool = false

@export var shuckCheckArea: Area2D


var target: TowerDefenseCharacter


var chewTimer: float = 0.0

var isSuck: bool = false

var isChew: bool = false

var eatCharacter: bool = false



func GetName() -> String:
    return "ChomperComponent"


func _exit_tree() -> void :
    if is_instance_valid(target):
        target.instance.canCollection = true
        target.state.process_mode = Node.PROCESS_MODE_INHERIT
        if target is TowerDefenseZombie:
            target.Walk()


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return

    if is_instance_valid(sprite):
        state.process_mode = Node.PROCESS_MODE_INHERIT
        sprite.animeCompleted.connect(AnimeCompleted)
        sprite.animeEvent.connect(AnimeEvent)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return




func IdleEntered() -> void :
    if parent.componentRunning:
        if parent is TowerDefensePlant:
            parent.Idle()
        elif parent is TowerDefenseZombie:
            parent.Walk()
    if isPartSprite:
        sprite.SetAnimation(partIdleAnimeClips, true, 0.2)


@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    if !alive:
        return
    if isPartSprite:
        sprite.timeScale = parent.timeScale * partIdleAnimeTimeScale
    if !TowerDefenseManager.IsGameRunning():
        return
    if !parent.inGame:
        return
    if !parent.componentAlive:
        return
    if parent.componentRunning:
        return
    if attackComponent.CanAttack():
        isSuck = false
        parent.Component()
        state.send_event("ToAttack")
        return
    if suckUse:
        GetTarget()
        if is_instance_valid(target):
            isSuck = true
            parent.Component()
            state.send_event("ToAttack")
            return


func IdleExited() -> void :
    pass


func AttackEntered() -> void :
    biteStart.emit()
    sprite.SetAnimation(biteStartAnimeClips, false, 0.5)
    if suckUse:
        if isSuck:
            sprite.AddAnimation(biteLoopAnimeClips, 0.0, true, 0.2)
        else:
            sprite.AddAnimation(biteEndAnimeClips, 0.0, false, 0.2)


func AttackProcessing(delta: float) -> void :
    if !is_instance_valid(sprite):
        return
    match sprite.clip:
        biteStartAnimeClips:
            sprite.timeScale = parent.timeScale * biteStartAnimeTimeScale
        biteLoopAnimeClips:
            sprite.timeScale = parent.timeScale * biteLoopAnimeTimeScale
        biteEndAnimeClips:
            sprite.timeScale = parent.timeScale * biteEndAnimeTimeScale
    if suckUse && isSuck:
        if sprite.clip == biteLoopAnimeClips:
            if !is_instance_valid(target):
                state.send_event("ToIdle")
                return
            if target.die || target.nearDie:
                target.instance.canCollection = true
                target.state.process_mode = Node.PROCESS_MODE_INHERIT
                target = null
                state.send_event("ToIdle")
                return
            if target.gridPos.y != parent.gridPos.y:
                target.instance.canCollection = true
                target.state.process_mode = Node.PROCESS_MODE_INHERIT
                target = null
                state.send_event("ToIdle")
                return
            if target is TowerDefenseZombie:
                if target.isPause:
                    target.instance.canCollection = true
                    target.state.process_mode = Node.PROCESS_MODE_INHERIT
                    target = null
                    state.send_event("ToIdle")
                    return
            if parent.CanTarget(target) && parent.CanCollision(target.instance.maskFlags):
                if target.global_position.x > global_position.x + 80:
                    target.instance.canCollection = false
                    target.state.process_mode = Node.PROCESS_MODE_DISABLED
                    target.global_position.x -= 200 * delta
                else:
                    sprite.SetAnimation("BiteEnd", false, 0.2)
            else:
                target.instance.canCollection = true
                target.state.process_mode = Node.PROCESS_MODE_INHERIT
                state.send_event("ToIdle")


func AttackExited() -> void :
    isSuck = false
    eatCharacter = false
    target = null


func ChewEntered() -> void :
    chewBegin.emit()
    chewTimer = 0.0
    isChew = true
    if !is_instance_valid(sprite):
        return
    if chewReadyAnimeClips != "":
        sprite.SetAnimation(chewReadyAnimeClips, false, 0.2)
        sprite.AddAnimation(chewAnimeClips, 0.0, true, 0.2)
    else:
        sprite.SetAnimation(chewAnimeClips, true, 0.2)


func ChewProcessing(delta: float) -> void :
    if !alive:
        return
    if !is_instance_valid(sprite):
        return
    sprite.timeScale = parent.timeScale * chewAnimeTimeScale
    chewProcessing.emit(delta)
    if sprite.clip == chewAnimeClips:
        if chewTimer < chewTime:
            chewTimer += delta
        else:
            chewOver.emit()
            state.send_event("ToSwallow")


func ChewExited() -> void :
    isChew = false
    pass


func SwallowEntered() -> void :
    if !is_instance_valid(sprite):
        return
    sprite.SetAnimation(swallowAnimeClips, false, 0.2)


@warning_ignore("unused_parameter")
func SwallowProcessing(delta: float) -> void :
    if !is_instance_valid(sprite):
        return
    sprite.timeScale = parent.timeScale * swallowAnimeTimeScale


func SwallowExited() -> void :
    pass



func AnimeCompleted(clip: String) -> void :
    match clip:
        biteStartAnimeClips:
            if !suckUse:
                if eatCharacter:
                    state.send_event("ToChew")
                else:
                    biteFail.emit()
                    state.send_event("ToIdle")
        biteEndAnimeClips:
            if eatCharacter:
                state.send_event("ToChew")
            else:
                biteFail.emit()
                state.send_event("ToIdle")
        swallowAnimeClips:
            state.send_event("ToIdle")
            swallowOver.emit()




@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    match command:
        biteEventName:
            AudioManager.AudioPlay("BigChomp", AudioManagerEnum.TYPE.SFX)
            if suckUse && isSuck:
                if is_instance_valid(target):
                    BitCharacter(target)
                else:
                    biteFail.emit()
            else:
                var attackTarget: TowerDefenseCharacter = attackComponent.target
                if is_instance_valid(attackTarget):
                    BitCharacter(attackTarget)
                else:
                    biteFail.emit()



func BitCharacter(_target: TowerDefenseCharacter) -> void :
    if _target.die || _target.nearDie:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and _target is TowerDefenseZombie:
        return
    var chewFlag: bool = false
    if parent.CanTarget(_target) && parent.CanCollision(_target.instance.maskFlags):
        BiteEventExecute(_target)
        if biteNoLimit:
            if _target is TowerDefenseZombie:
                if _target.instance.biteHurt == -1:
                    if !biteOnly:
                        chewFlag = true
                    else:
                        _target.Hurt((_target.instance.biteHurt if biteAttack == -1 else biteAttack), true, Vector2.ZERO, false)
                else:
                    _target.Hurt((_target.instance.biteHurt if biteAttack == -1 else biteAttack), true, Vector2.ZERO, false)
            else:
                _target.Hurt((_target.instance.biteHurt if biteAttack == -1 else biteAttack), true, Vector2.ZERO, false)
        else:
            if _target.instance.biteHurt == -1:
                _target.instance.ArmorClear()
                _target.Hurt((100000.0 if biteAttack == -1 else biteAttack), true, Vector2.ZERO, false)
            else:
                _target.Hurt((_target.instance.biteHurt if biteAttack == -1 else biteAttack), true, Vector2.ZERO, false)
    if _target.die || _target.nearDie:
        chewFlag = true
    if !biteOnly && chewFlag:
        _target.isChomp = true
        _target.Destroy()
        eatCharacter = true



func BiteEventExecute(_target: TowerDefenseCharacter) -> void :
    for event in biteEvent:
        event.Execute(parent.global_position, _target)



func GetTarget() -> TowerDefenseCharacter:
    var characterList = TowerDefenseManager.GetCharacterTargetLineFromArea(parent, shuckCheckArea, true)
    characterList.sort_custom(
        func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
            return abs(a.global_position.x - global_position.x) < abs(b.global_position.x - global_position.x)
    )
    for character: TowerDefenseCharacter in characterList:
        if character is TowerDefenseZombie:
            if character.instance.zombiePhysique <= TowerDefenseEnum.ZOMBIE_PHYSIQUE.NORMAL:
                target = character
                return character
    return null

func ExportComponentSave() -> Dictionary:
    var data: Dictionary = {
        "chewTimer": chewTimer, 
        "isSuck": isSuck, 
        "isChew": isChew, 
        "eatCharacter": eatCharacter, 
    }
    if is_instance_valid(target):
        data["target"] = target.name.validate_node_name()
    return data

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    chewTimer = _data.get("chewTimer", 0.0)
    isSuck = _data.get("isSuck", false)
    isChew = _data.get("isChew", false)
    eatCharacter = _data.get("eatCharacter", false)
    var targetName: String = _data.get("target", "")
    if targetName != "" and _owner.charcterDicionary.has(targetName):
        target = _owner.charcterDicionary[targetName]

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "chewTimer": chewTimer, 
        "isSuck": isSuck, 
        "isChew": isChew, 
        "eatCharacter": eatCharacter, 
    }
    if is_instance_valid(target):
        data["targetSyncId"] = target.sync_id
    if is_instance_valid(state) and is_instance_valid(state._state) and state._state is CompoundState and is_instance_valid(state._state._active_state):
        data["state"] = state._state._active_state.name
    return data

func SyncDeserialize(data: Dictionary) -> void :
    chewTimer = data.get("chewTimer", 0.0)
    isSuck = data.get("isSuck", false)
    isChew = data.get("isChew", false)
    eatCharacter = data.get("eatCharacter", false)
    if data.has("targetSyncId"):
        var target_sync_id: int = data["targetSyncId"]
        if target_sync_id >= 0 and is_instance_valid(TowerDefenseManager.currentControl):
            var ctrl = TowerDefenseManager.currentControl
            if ctrl._sync_characters.has(target_sync_id):
                target = ctrl._sync_characters[target_sync_id]
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
