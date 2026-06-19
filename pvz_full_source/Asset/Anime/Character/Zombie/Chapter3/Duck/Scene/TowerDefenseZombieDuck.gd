@tool
extends TowerDefenseZombie

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return

    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliters(["Zombie_duckytube", "Zombie_whitewater", "Zombie_whitewater2"], true)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func HitpointsNearDie() -> void :
    super.HitpointsNearDie()
    DestroySet()

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    DestroySet()

func DestroySet() -> void :
    if over:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        over = true
        return
    over = true
    if !isSmash && !isExplode && !isChomp:
        SpawnDuckytube()
    await get_tree().physics_frame

func SpawnDuckytube() -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("Duckytube")
    var duckytube = packetConfig.Create(global_position, gridPos)
    characterNode.add_child.call_deferred(duckytube)
    if instance.hypnoses:
        duckytube.Hypnoses.call_deferred()
