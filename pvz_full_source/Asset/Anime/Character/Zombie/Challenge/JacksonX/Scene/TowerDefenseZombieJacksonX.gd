@tool
extends TowerDefenseZombie

var dancingComponent: DancingComponent
var disco: TowerDefenseCharacter
var isSpawnBackup: bool = false
var _pending_disco_name: String = ""

@export var dancerPacketName: String = "":
    set(value):
        dancerPacketName = value
        if value != "" && is_instance_valid(dancingComponent):
            dancingComponent.dancerPacketName = value

func RemoveDancer(dancer: TowerDefenseCharacter) -> void :
    if is_instance_valid(dancingComponent):
        dancingComponent.RemoveDancer(dancer)

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint() || Global.isEditor:
        return
    dancingComponent = componentManager.GetComponentFromType("DancingComponent") as DancingComponent
    if is_instance_valid(dancingComponent):
        sprite.animeCompleted.disconnect(dancingComponent.AnimeCompleted)
        sprite.animeEvent.disconnect(dancingComponent.AnimeEvent)
        if dancerPacketName != "":
            dancingComponent.dancerPacketName = dancerPacketName

func WalkEntered() -> void :
    super.WalkEntered()
    if is_instance_valid(dancingComponent):
        dancingComponent.sprite.scale.x = dancingComponent.normalSpriteScaleX
        dancingComponent.walkTime = dancingComponent.walkTimeInit

func Walk() -> void :
    if die:
        state.send_event("ToDie")
        return
    if is_instance_valid(dancingComponent):
        if dancingComponent.OnWalk():
            return
    state.send_event("ToWalk")

func AttackProcessing(delta: float) -> void :
    super.AttackProcessing(delta)
    if is_instance_valid(dancingComponent):
        dancingComponent.OnAttackProcessing(delta)

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
            if isSpawnBackup:
                for dancer: TowerDefenseCharacter in dancingComponent.dancerList:
                    if is_instance_valid(dancer):
                        if !dancer.die && !dancer.nearDie:
                            dancer.Walk()
                Walk()
                dancingComponent.state.send_event("ToIdle")
                isSpawnBackup = false
            else:
                await get_tree().physics_frame
                if is_instance_valid(disco):
                    disco.moonWalkOver = true
                    disco.state.send_event("ToPoint")
                dancingComponent.state.send_event("ToPoint")
                isSpawnBackup = true
        dancingComponent.walkAnimeClip:
            dancingComponent.walkTime -= 1
            if !die && !nearDie:
                if dancingComponent.walkTime <= 0:
                    if dancingComponent.CanSpawnDancer():
                        Component()
                        dancingComponent.state.send_event("ToPoint")
                        return
                    else:
                        for dancer: TowerDefenseCharacter in dancingComponent.dancerList:
                            if is_instance_valid(dancer):
                                if !dancer.die && !dancer.nearDie:
                                    if dancer.sprite.clip == dancingComponent.walkAnimeClip:
                                        dancer.state.send_event("ToDance")
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
                        for dancer: TowerDefenseCharacter in dancingComponent.dancerList:
                            if is_instance_valid(dancer):
                                if !dancer.die && !dancer.nearDie:
                                    if dancer.sprite.clip == dancingComponent.armRiseAnimeClip:
                                        dancer.Walk()
                        Walk()
                        dancingComponent.state.send_event("ToIdle")
                        return
            else:
                Die()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    if !is_instance_valid(dancingComponent):
        return
    match command:
        "spawn":
            if !die && !nearDie:
                if isSpawnBackup:
                    dancingComponent.SpawnDancer()
                else:
                    SpawnDisco()
                if is_instance_valid(dancingComponent.spotlight):
                    dancingComponent.spotlight.visible = true
                if is_instance_valid(dancingComponent.spotlight2):
                    dancingComponent.spotlight2.visible = true
                dancingComponent.ChangeSpotlightColor()
                if !dancingComponent.firstSpawn:
                    dancingComponent.firstSpawn = true
                    if dancingComponent.spotlightAudioName != "":
                        AudioManager.AudioPlay(dancingComponent.spotlightAudioName, AudioManagerEnum.TYPE.SFX)

func SpawnDisco() -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieDisco")
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    var gridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
    var randomList: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0)]
    if gridPos.y > 1:
        randomList.append(Vector2i(0, -1))
    if gridPos.y < gridNum.y:
        randomList.append(Vector2i(0, 1))
    var offset: Vector2i = randomList.pick_random()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    var disco_pos: Vector2
    var disco_grid: Vector2i = gridPos + offset
    if offset.x != 0:
        disco_pos = global_position + Vector2(gridSize.x * offset.x * 1.25, 0)
    else:
        disco_pos = Vector2(global_position.x, TowerDefenseManager.GetMapLineY(gridPos.y + offset.y))
    disco = packetConfig.Create(disco_pos, disco_grid, 0)
    characterNode.add_child.call_deferred(disco)
    ( func():
        if is_instance_valid(disco):
            if is_instance_valid(disco.instance):
                disco.instance.hitpointScale = _hitpointScale
            if is_instance_valid(disco.transformPoint):
                disco.transformPoint.scale = _scale).call_deferred()
    disco.Rise.call_deferred(1.0)
    disco.invisible = invisible
    if instance.hypnoses:
        disco.Hypnoses.call_deferred()
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, disco)
            MultiPlayerManager.SendSpawnCharacterAt("ZombieDisco", disco_grid.x, disco_grid.y, _sync_id, _hitpointScale, _scale.x, instance.hypnoses, 1.0, true, disco_pos.x, disco_pos.y)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if is_instance_valid(dancingComponent):
        dancingComponent.dancerList.clear()
        dancingComponent.dancerList.resize(4)

func ExportVariantSave() -> Dictionary:
    var data: Dictionary = {
        "isSpawnBackup": isSpawnBackup, 
    }
    if is_instance_valid(disco):
        data["discoNodeName"] = disco.name
    return data

func ImportVariantSave(data: Dictionary) -> void :
    isSpawnBackup = data.get("isSpawnBackup", false)
    if data.has("discoNodeName"):
        _pending_disco_name = data["discoNodeName"]

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if _pending_disco_name != "":
        var _characterNode = TowerDefenseManager.GetCharacterNode()
        if is_instance_valid(_characterNode):
            var node = _characterNode.get_node_or_null(_pending_disco_name)
            if is_instance_valid(node):
                disco = node
        _pending_disco_name = ""
