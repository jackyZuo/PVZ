@tool
extends TowerDefenseZombie

var waitGrab: bool = false
var waitDown: bool = false
var hasPlant: bool = false
@onready var bungeeTarget: Sprite2D = %BungeeTarget

var waitGrabTimer = 0.0
var waitDownTimer = 0.0

var canBlock: bool = true

var dropTween: Tween

var grabOver: bool = false
var downOver: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    targetRegistrationComponent.canProjectileCheck = false
    targetRegistrationComponent.canCarry = false
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    add_to_group("Bungi", true)
    if TowerDefenseManager.IsGameRunning():
        z = 600.0
        isGround = false

func HitpointsNearDie() -> void :
    super.HitpointsNearDie()
    Destroy()

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    Destroy()

func Walk() -> void :
    state.send_event("ToDrop")

func IdleEntered() -> void :
    super.IdleEntered()

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if waitDown:
        if waitDownTimer < 3.0:
            if !sprite.pause:
                waitDownTimer += delta * timeScale
        else:
            waitDown = false
            for buffKey in buff.buffDictionary.keys():
                if buffKey != "Hypnoses":
                    buff.BuffDelete(buffKey)
            state.send_event("ToDown")

func Spawn() -> void :
    z = 600.0
    isGround = false
    var bungiTargets: Array[Vector2i] = []
    for bungi in get_tree().get_nodes_in_group("Bungi"):
        if bungi != self && bungi.gridPos != Vector2i(-1, -1):
            bungiTargets.append(bungi.gridPos)
    var plantList = get_tree().get_nodes_in_group("Plant").filter(
        func(checkCharcter: TowerDefenseCharacter):
            if checkCharcter is TowerDefensePlantBowlingBase:
                return false
            if checkCharcter.gridPos in bungiTargets:
                return false
            var _cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(checkCharcter.gridPos)
            for cellCharacter in _cell.GetCharacterList():
                if cellCharacter.config.name == "TrashBin":
                    return false
            return true
    )
    if plantList.size() <= 0:
        Destroy()
        gridPos = Vector2(randi_range(0, TowerDefenseManager.GetMapGridNum().x), randi_range(0, TowerDefenseManager.GetMapGridNum().y))
        return
    var target: TowerDefenseCharacter = plantList.pick_random()
    global_position = TowerDefenseManager.GetMapCellPlantPos(target.gridPos)
    gridPos = target.gridPos

func DropEntered() -> void :
    instance.canBeCollection = false
    instance.invincible = true
    z = 600.0
    isGround = false
    bungeeTarget.visible = true
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(bungeeTarget, ^"position", Vector2(0, 15 - cell.GetGroundHeight()), 0.5).from(Vector2(0, -600 + 15))
    await get_tree().create_timer(1.0, false).timeout
    AudioManager.AudioPlay("BungeeScream", AudioManagerEnum.TYPE.SFX)
    await get_tree().create_timer(1.0, false).timeout
    dropTween = create_tween()
    dropTween.set_ease(Tween.EASE_OUT)
    dropTween.set_trans(Tween.TRANS_CUBIC)
    dropTween.tween_property(self, ^"z", cell.GetGroundHeight(), 1.0)

    sprite.SetAnimation("Drop", true, 0.2)
    await dropTween.finished
    isGround = true
    groundHeight = cell.GetGroundHeight()
    z = groundHeight
    waitGrab = false
    waitDown = true
    instance.invincible = false
    instance.canBeCollection = true
    targetRegistrationComponent.canProjectileCheck = true
    instance.maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
    Idle()

@warning_ignore("unused_parameter")
func DropProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func DropExited() -> void :
    pass

func DownEntered() -> void :
    waitGrab = true
    instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL - TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES
    targetRegistrationComponent.canProjectileCheck = false
    instance.invincible = true
    sprite.SetAnimation("Down", false, 0.2)

@warning_ignore("unused_parameter")
func DownProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func DownExited() -> void :
    pass

func DownIdleEntered() -> void :
    sprite.timeScale = timeScale
    sprite.SetAnimation("DownIdle", true, 0.2)

func DownIdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale
    if waitGrab:
        if waitGrabTimer < 5.0:
            if !sprite.pause:
                waitGrabTimer += delta * timeScale
        else:
            waitGrab = false
            for buffKey in buff.buffDictionary.keys():
                if buffKey != "Hypnoses":
                    buff.BuffDelete(buffKey)
            state.send_event("ToGrab")

func DownIdleExited() -> void :
    pass

func GrabEntered() -> void :
    instance.unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL - TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES
    targetRegistrationComponent.canProjectileCheck = false
    instance.invincible = true
    sprite.SetAnimation("Grab", false, 0.2)

@warning_ignore("unused_parameter")
func GrabProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func GrabExited() -> void :
    pass

func RiseEntered() -> void :
    sprite.SetAnimation("Rise", true, 0.2)
    var time: float = 1.5
    if !canBlock:
        time = 0.75
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(bungeeTarget, ^"position", Vector2(0, -600 + 15), time)
    tween.tween_property(self, ^"z", 600, time)
    await tween.finished
    Destroy()

@warning_ignore("unused_parameter")
func RiseProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func RiseExited() -> void :
    pass

@warning_ignore("unused_parameter")
func AnimeEvent(command: String, argument: Variant) -> void :
    match command:
        "down":
            if downOver:
                return
            downOver = true
            var trashBinPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("TrashBin")
            if cell.CanPacketPlant(trashBinPacket):
                trashBinPacket.Plant(gridPos, false)
        "grab":
            if grabOver:
                return
            grabOver = true
            AudioManager.AudioPlay("Floop", AudioManagerEnum.TYPE.SFX)
            cell = TowerDefenseManager.GetMapCell(gridPos)
            var plantsToDestroy: Array[TowerDefenseCharacter] = []
            for getTarget: TowerDefenseCharacter in cell.GetCharacterList().duplicate():
                if getTarget.config.name == "TrashBin":
                    hasPlant = true
                    getTarget.die = true
                    getTarget.Destroy(false)
                    getTarget.sprite.pause = true
                    getTarget.shadowSprite.visible = false
                    getTarget.shadowSprite.texture = null
                    getTarget.reparent(self.spriteGroup)
                else:
                    if getTarget.camp == camp:
                        continue
                    if getTarget is not TowerDefensePlant:
                        continue
                    if getTarget is TowerDefensePlantBowlingBase:
                        continue
                    plantsToDestroy.append(getTarget)
            if hasPlant:
                for plant in plantsToDestroy:
                    plant.Destroy()
            else:
                var getTarget = cell.GetTarget(instance.collisionFlags, camp, false, true)
                if !is_instance_valid(getTarget):
                    var targets = TowerDefenseManager.GetCharacterTargetNear(self)
                    for target in targets:
                        if target.gridPos == gridPos:
                            getTarget = target
                            break
                if is_instance_valid(getTarget):
                    hasPlant = true
                    getTarget.die = true
                    getTarget.Destroy(false)
                    getTarget.sprite.pause = true
                    getTarget.shadowSprite.visible = false
                    getTarget.shadowSprite.texture = null
                    getTarget.reparent(self.spriteGroup)

func AnimeCompleted(clip: String) -> void :
    match clip:
        "Down":
            state.send_event("ToDownIdle")
        "Grab":
            state.send_event("ToRise")

func CanBlock() -> bool:
    return canBlock && z <= 50

func ExportVariantSave() -> Dictionary:
    return {
        "waitGrab": waitGrab, 
        "hasPlant": hasPlant, 
        "waitDownTimer": waitDownTimer, 
        "waitGrabTimer": waitGrabTimer, 
        "canBlock": canBlock, 
        "grabOver": grabOver, 
        "waitDown": waitDown, 
        "downOver": downOver
    }

func ImportVariantSave(data: Dictionary) -> void :
    waitGrab = data.get("waitGrab", false)
    hasPlant = data.get("hasPlant", false)
    waitDownTimer = data.get("waitDownTimer", 0.0)
    waitGrabTimer = data.get("waitGrabTimer", 0.0)
    canBlock = data.get("canBlock", true)
    grabOver = data.get("grabOver", false)
    waitDown = data.get("waitDown", false)
    downOver = data.get("downOver", false)

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    if is_instance_valid(dropTween):
        dropTween.kill()
    canBlock = false
    instance.invincible = true
    sprite.SetFliter("bin", false)
    var trashBinPacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("TrashBin")
    if cell.CanPacketPlant(trashBinPacket):
        trashBinPacket.Plant(gridPos)
    state.send_event("ToRise")
