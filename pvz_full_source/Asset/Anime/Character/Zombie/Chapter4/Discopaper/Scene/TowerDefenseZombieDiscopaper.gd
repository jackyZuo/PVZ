@tool
extends TowerDefenseZombie
const ZOMBIE_PAPER_MADHEAD = preload("uid://chsy8qvq8nmd")

@onready var spotlight2: Sprite2D = %Spotlight2
@onready var spotlight: Sprite2D = %Spotlight
@export var spotlightGrandient: Gradient

var walkTime: int = 4
var angry: bool = false:
    set(_angry):
        angry = _angry
        if angry:
            walkAnimeClip = "AngryWalk"
            swimAnimeClip = "AngryWalk"
            sprite.SetReplace("Zombie_dancer__head.png", ZOMBIE_PAPER_MADHEAD)
        else:
            walkAnimeClip = "Walk"
            swimAnimeClip = "Walk"

var dancerList: Array[TowerDefenseCharacter] = []
@export var dancerPacketName: String = "ZombieBackuppaper"

var firstSpawn: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    dancerList.resize(4)

func PointEntered() -> void :

    sprite.SetAnimation("PointUp", false, 0.2)
    sprite.AddAnimation("PointDown", 0.75, false, 0.2)

@warning_ignore("unused_parameter")
func PointProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.75

func PointExited() -> void :
    pass

func WalkEntered() -> void :
    super.WalkEntered()
    sprite.scale.x = 0.8
    for dancer in dancerList:
        if is_instance_valid(dancer):
            dancer.timeScale = timeScale
            dancer.walkSpeedScale = walkSpeedScale
    walkTime = 4

func WalkProcessing(delta: float) -> void :
    groundMoveComponent.alive = CanWalk()
    super.WalkProcessing(delta)

func Walk() -> void :
    state.send_event("ToWalk")

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    groundMoveComponent.alive = false

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func GaspEntered() -> void :
    sprite.SetAnimation("Gasp", false, 0.1)

@warning_ignore("unused_parameter")
func GaspProcessing(delta: float) -> void :
    sprite.timeScale = timeScale

func GaspExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "PointDown":
            for dancer in dancerList:
                if is_instance_valid(dancer):
                    if !dancer.die && !dancer.nearDie:
                        dancer.Walk()
            Walk()
        "AngryWalk":
            if angry:
                walkTime -= 1
            if ( !die && !nearDie):
                if walkTime <= 0:
                    if CanSpawnDancer():
                        state.send_event("ToPoint")
                        return
            else:
                Die()
        "Gasp":
            AudioManager.AudioPlay("NewspaperRarrgh", AudioManagerEnum.TYPE.SFX)
            sprite.SetReplace("Zombie_head.png", ZOMBIE_PAPER_MADHEAD)
            timeScaleInit = 2.0
            angry = true
            state.send_event("ToPoint")
func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "spawn":
            if !die && !nearDie:
                SpawnDancer()
                spotlight.visible = true
                spotlight2.visible = true
                ChangeSpotlightColor()
                if !firstSpawn:
                    firstSpawn = true
                    AudioManager.AudioPlay("Dancer", AudioManagerEnum.TYPE.SFX)

func CanWalk() -> bool:
    if is_instance_valid(dancerList[0]):
        if dancerList[0].sprite.clip != "Walk":
            return false
    if is_instance_valid(dancerList[1]):
        if dancerList[1].sprite.clip != "Walk":
            return false
    if is_instance_valid(dancerList[2]):
        if dancerList[2].sprite.clip != "Walk":
            return false
    if is_instance_valid(dancerList[3]):
        if dancerList[3].sprite.clip != "Walk":
            return false
    return true

func CanSpawnDancer() -> bool:
    var gridNum: Vector2 = TowerDefenseManager.GetMapGridNum()
    if gridPos.y > 1:
        if !is_instance_valid(dancerList[0]):
            return true
    if gridPos.y < gridNum.y:
        if !is_instance_valid(dancerList[1]):
            return true
    if !is_instance_valid(dancerList[2]):
        return true
    if !is_instance_valid(dancerList[3]):
        return true
    return false

func SpawnDancer() -> void :
    if isShow:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(dancerPacketName)
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    if gridPos.y > 1:
        if !is_instance_valid(dancerList[0]):
            var dancer = packetConfig.Create(Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y - 1)), gridPos - Vector2i(0, 1), 0)
            characterNode.add_child.call_deferred(dancer)
            ( func():
                if is_instance_valid(dancer):
                    if is_instance_valid(dancer.instance):
                        dancer.instance.hitpointScale = _hitpointScale
                    if is_instance_valid(dancer.transformPoint):
                        dancer.transformPoint.scale = _scale).call_deferred()
            dancer.Rise.call_deferred(1.5)
            dancer.jackson = self
            dancer.invisible = invisible
            if instance.hypnoses:
                dancer.Hypnoses.call_deferred()
            dancerList[0] = dancer
    if gridPos.y < gridNum.y:
        if !is_instance_valid(dancerList[1]):
            var dancer = packetConfig.Create(Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y + 1)), gridPos + Vector2i(0, 1), 0)
            characterNode.add_child.call_deferred(dancer)
            ( func():
                if is_instance_valid(dancer):
                    if is_instance_valid(dancer.instance):
                        dancer.instance.hitpointScale = _hitpointScale
                    if is_instance_valid(dancer.transformPoint):
                        dancer.transformPoint.scale = _scale).call_deferred()
            dancer.Rise.call_deferred(1.5)
            dancer.jackson = self
            dancer.invisible = invisible
            if instance.hypnoses:
                dancer.Hypnoses.call_deferred()
            dancerList[1] = dancer
    if !is_instance_valid(dancerList[2]):
        var dancer = packetConfig.Create(global_position - Vector2(gridSize.x * 1.25, 0), gridPos - Vector2i(1, 0), 0)
        characterNode.add_child.call_deferred(dancer)
        ( func():
            if is_instance_valid(dancer):
                if is_instance_valid(dancer.instance):
                    dancer.instance.hitpointScale = _hitpointScale
                if is_instance_valid(dancer.transformPoint):
                    dancer.transformPoint.scale = _scale).call_deferred()
        dancer.Rise.call_deferred(1.5)
        dancer.jackson = self
        dancer.invisible = invisible
        if instance.hypnoses:
            dancer.Hypnoses.call_deferred()
        dancerList[2] = dancer
    if !is_instance_valid(dancerList[3]):
        var dancer = packetConfig.Create(global_position + Vector2(gridSize.x * 1.25, 0), gridPos + Vector2i(1, 0), 0)
        characterNode.add_child.call_deferred(dancer)
        ( func():
            if is_instance_valid(dancer):
                if is_instance_valid(dancer.instance):
                    dancer.instance.hitpointScale = _hitpointScale
                if is_instance_valid(dancer.transformPoint):
                    dancer.transformPoint.scale = _scale).call_deferred()
        dancer.Rise.call_deferred(1.5)
        dancer.jackson = self
        dancer.invisible = invisible
        if instance.hypnoses:
            dancer.Hypnoses.call_deferred()
        dancerList[3] = dancer

func ChangeSpotlightColor() -> void :
    var color = spotlightGrandient.sample(randf())
    spotlight.modulate = color
    spotlight2.modulate = color
    get_tree().create_timer(3.0, false).timeout.connect(ChangeSpotlightColor)

func RemoveDancer(dancer: TowerDefenseCharacter) -> void :
    var pos = dancerList.find(dancer)
    if pos != -1:
        dancerList[pos] = null

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    for dancer in dancerList:
        if is_instance_valid(dancer):
            dancer.jackson = null
    dancerList.clear()
    dancerList.resize(4)

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Paper":
            state.send_event("ToGasp")
            AudioManager.AudioPlay("NewspaperRip", AudioManagerEnum.TYPE.SFX)

func ExportVariantSave() -> Dictionary:
    return {
        "walkTime": walkTime, 
        "angry": angry, 
        "firstSpawn": firstSpawn, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    walkTime = data.get("walkTime", 4)
    angry = data.get("angry", false)
    firstSpawn = data.get("firstSpawn", false)
