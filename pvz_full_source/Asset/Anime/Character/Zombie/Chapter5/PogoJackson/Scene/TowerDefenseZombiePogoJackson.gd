@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2

var dancingComponent: DancingComponent

@export var dancerPacketName: String = "":
    set(value):
        dancerPacketName = value
        if value != "" && is_instance_valid(dancingComponent):
            dancingComponent.dancerPacketName = value

func RemoveDancer(dancer: TowerDefenseCharacter) -> void :
    if is_instance_valid(dancingComponent):
        dancingComponent.RemoveDancer(dancer)

var isJump: bool = false

var hasPogo: bool = true:
    set(_hasPogo):
        hasPogo = _hasPogo
        if !hasPogo:
            idleAnimeClip = "Walk"

var pogoPlant: bool = false
var jumpToPos: float
var jumpWait: int = 1

var isSpawn: bool = false
var timer: float = 5.0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    dancingComponent = componentManager.GetComponentFromType("DancingComponent") as DancingComponent
    if is_instance_valid(dancingComponent):
        sprite.animeCompleted.disconnect(dancingComponent.AnimeCompleted)
        sprite.animeEvent.disconnect(dancingComponent.AnimeEvent)
        if dancerPacketName != "":
            dancingComponent.dancerPacketName = dancerPacketName
        else:
            dancingComponent.dancerPacketName = "ZombiePogoDancer"
    ySpeed = -300
    if TowerDefenseManager.GetMapIsChess():
        timeScaleInit *= 2

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if timer > 0.0:
        timer -= delta

func PogoEntered() -> void :
    sprite.SetAnimation("Pogo", true, 0.2)
    if isGround:
        ySpeed = -300

@warning_ignore("unused_parameter")
func PogoProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !pogoPlant:
        if !sprite.pause:
            if global_position.x > groundRight:
                global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * 2.0 * (-1 if sprite.playBack else 1)
            else:
                global_position.x -= 30.0 * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
        if !sprite.pause && attackComponent.CanAttack():
            pogoPlant = true
            jumpToPos = global_position.x - TowerDefenseManager.GetMapGridSize().x * scale.x - 10 * scale.x
    else:
        if isJump:
            if attackComponent2.CanAttack():
                if is_instance_valid(attackComponent2.target):
                    if attackComponent2.target.instance.height >= TowerDefenseEnum.CHARACTER_HEIGHT.TALL:
                        instance.ArmorDelete("Pogo")
                        hasPogo = false
                        isJump = false
                        AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
                        Walk()
    if !isSpawn:
        if timer <= 0.0:
            if is_instance_valid(dancingComponent):
                if dancingComponent.CanSpawnDancer():
                    sprite.SetAnimation("PogoPointUp", false, 0.0)
                    sprite.AddAnimation("PogoPointDown", 0.0, false, 0.0)
                    sprite.AddAnimation("Pogo", 0.0, false, 0.0)
                    isSpawn = true

func PogoExited() -> void :
    pass

func WalkEntered() -> void :
    super.WalkEntered()
    if is_instance_valid(dancingComponent):
        dancingComponent.OnWalkEntered()

func WalkProcessing(delta: float) -> void :
    super.WalkProcessing(delta)

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnAttackProcessing(delta)

func Walk() -> void :
    if hasPogo:
        state.send_event("ToPogo")
    else:
        if die:
            state.send_event("ToDie")
            return
        if is_instance_valid(dancingComponent):
            if dancingComponent.OnWalk():
                return
        state.send_event("ToWalk")

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnDieProcessing()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    if !inGame:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !is_instance_valid(dancingComponent):
        return
    match clip:
        dancingComponent.pointDownAnimeClip:
            Walk()
            dancingComponent.state.send_event("ToIdle")
        dancingComponent.walkAnimeClip:
            dancingComponent.walkTime -= 1
            if !die && !nearDie:
                if dancingComponent.walkTime <= 0:
                    if dancingComponent.CanSpawnDancer():
                        Component()
                        dancingComponent.state.send_event("ToPoint")
                        return
                    else:
                        Component()
                        dancingComponent.state.send_event("ToDance")
                        return
            else:
                Die()
        dancingComponent.armRiseAnimeClip:
            if dancingComponent.armRiseFlipSprite:
                sprite.scale.x = - sprite.scale.x
            dancingComponent.danceTime -= 1
            if !die && !nearDie:
                if dancingComponent.danceTime <= 0:
                    if dancingComponent.CanSpawnDancer():
                        Component()
                        dancingComponent.state.send_event("ToPoint")
                        return
                    else:
                        Walk()
                        dancingComponent.state.send_event("ToIdle")
                        return
            else:
                Die()

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Pogo":
            instance.unUseBuffFlags = 0
            isJump = false
            hasPogo = false
            if is_instance_valid(groundHeightComponent):
                groundHeightComponent.handleWaterHeight = true
            if inWater:
                groundHeight = - waterHeight
            Walk()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    if !is_instance_valid(dancingComponent):
        return
    match command:
        "spawn":
            if !die && !nearDie:
                SpawnDancer()
                if is_instance_valid(dancingComponent.spotlight):
                    dancingComponent.spotlight.visible = true
                if is_instance_valid(dancingComponent.spotlight2):
                    dancingComponent.spotlight2.visible = true
                dancingComponent.ChangeSpotlightColor()
                if !dancingComponent.firstSpawn:
                    dancingComponent.firstSpawn = true
                    if dancingComponent.spotlightAudioName != "":
                        AudioManager.AudioPlay(dancingComponent.spotlightAudioName, AudioManagerEnum.TYPE.SFX)
                isSpawn = false

func SpawnDancer() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(dancingComponent.dancerPacketName)
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    if gridPos.y > 1:
        if !is_instance_valid(dancingComponent.dancerList[0]):
            var dancer = packetConfig.Create(Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y - 1)), gridPos - Vector2i(0, 1), 0)
            characterNode.add_child.call_deferred(dancer)
            ( func():
                if is_instance_valid(dancer):
                    if is_instance_valid(dancer.instance):
                        dancer.instance.hitpointScale = _hitpointScale
                    if is_instance_valid(dancer.transformPoint):
                        dancer.transformPoint.scale = _scale).call_deferred()
            dancer.z = 600
            dancer.jackson = self
            dancer.invisible = invisible
            dancer.WalkReady.call_deferred()
            if instance.hypnoses:
                dancer.Hypnoses.call_deferred()
            dancingComponent.dancerList[0] = dancer
    if gridPos.y < gridNum.y:
        if !is_instance_valid(dancingComponent.dancerList[1]):
            var dancer = packetConfig.Create(Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y + 1)), gridPos + Vector2i(0, 1), 0)
            characterNode.add_child.call_deferred(dancer)
            ( func():
                if is_instance_valid(dancer):
                    if is_instance_valid(dancer.instance):
                        dancer.instance.hitpointScale = _hitpointScale
                    if is_instance_valid(dancer.transformPoint):
                        dancer.transformPoint.scale = _scale).call_deferred()
            dancer.z = 600
            dancer.jackson = self
            dancer.invisible = invisible
            dancer.WalkReady.call_deferred()
            if instance.hypnoses:
                dancer.Hypnoses.call_deferred()
            dancingComponent.dancerList[1] = dancer
    if !is_instance_valid(dancingComponent.dancerList[2]):
        var dancer = packetConfig.Create(global_position - Vector2(gridSize.x * 1.25, 0), gridPos - Vector2i(1, 0), 0)
        characterNode.add_child.call_deferred(dancer)
        ( func():
            if is_instance_valid(dancer):
                if is_instance_valid(dancer.instance):
                    dancer.instance.hitpointScale = _hitpointScale
                if is_instance_valid(dancer.transformPoint):
                    dancer.transformPoint.scale = _scale).call_deferred()
        dancer.z = 600
        dancer.jackson = self
        dancer.invisible = invisible
        dancer.WalkReady.call_deferred()
        if instance.hypnoses:
            dancer.Hypnoses.call_deferred()
        dancingComponent.dancerList[2] = dancer
    if !is_instance_valid(dancingComponent.dancerList[3]):
        var dancer = packetConfig.Create(global_position + Vector2(gridSize.x * 1.25, 0), gridPos + Vector2i(1, 0), 0)
        characterNode.add_child.call_deferred(dancer)
        ( func():
            if is_instance_valid(dancer):
                if is_instance_valid(dancer.instance):
                    dancer.instance.hitpointScale = _hitpointScale
                if is_instance_valid(dancer.transformPoint):
                    dancer.transformPoint.scale = _scale).call_deferred()
        dancer.z = 600
        dancer.jackson = self
        dancer.invisible = invisible
        dancer.WalkReady.call_deferred()
        if instance.hypnoses:
            dancer.Hypnoses.call_deferred()
        dancingComponent.dancerList[3] = dancer

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnHypnoses()

func ExportVariantSave() -> Dictionary:
    return {
        "hasPogo": hasPogo, 
        "isJump": isJump, 
        "pogoPlant": pogoPlant, 
        "jumpToPos": jumpToPos, 
        "jumpWait": jumpWait, 
        "isSpawn": isSpawn, 
        "timer": timer, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hasPogo = data.get("hasPogo", true)
    isJump = data.get("isJump", false)
    pogoPlant = data.get("pogoPlant", false)
    jumpToPos = data.get("jumpToPos", 0.0)
    jumpWait = data.get("jumpWait", 1)
    isSpawn = data.get("isSpawn", false)
    timer = data.get("timer", 5.0)

func InWater() -> void :
    super.InWater()
    if hasPogo:
        groundHeight = 0.0
        if is_instance_valid(groundHeightComponent):
            groundHeightComponent.handleWaterHeight = false

func OutWater() -> void :
    if hasPogo && is_instance_valid(groundHeightComponent):
        groundHeightComponent.handleWaterHeight = true
    super.OutWater()
    if !hasPogo:
        return
    ySpeed = -300

func Land() -> void :
    if !hasPogo:
        return
    isJump = false
    gravity = 490
    ySpeed = -300
    if pogoPlant:
        isJump = true
        if jumpWait > 0:
            jumpWait -= 1
        else:
            jumpWait = 1
            var tween = create_tween()
            tween.set_ease(Tween.EASE_IN_OUT)
            tween.set_trans(Tween.TRANS_SINE)
            tween.tween_property(self, ^"global_position:x", jumpToPos, 0.5)
            ySpeed = -400
            await tween.finished
            pogoPlant = false
        await get_tree().create_timer(0.2, false).timeout
        isJump = false

func CanBlock() -> bool:
    return hasPogo

func BlockType() -> String:
    return "Jump"

@warning_ignore("unused_parameter")
func Block(target: TowerDefenseCharacter) -> void :
    instance.ArmorDelete("Pogo")
    hasPogo = false
    isJump = false
    if is_instance_valid(groundHeightComponent):
        groundHeightComponent.handleWaterHeight = true
    if inWater:
        groundHeight = - waterHeight
    AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
    Walk()
