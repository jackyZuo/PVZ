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
    sprite.SetFliters(["anim_Pot"], false)
    DestroySet()

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    sprite.SetFliters(["anim_Pot"], false)
    DestroySet()

func DestroySet() -> void :
    if over:
        return
    over = true
    SpawnVase()
    await get_tree().physics_frame

func SpawnVase() -> void :
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("VaseNormal")
    var getGridPos = TowerDefenseManager.GetMapGridPos(global_position)
    var vase = packetConfig.Create(global_position, getGridPos)
    vase.useEnterAnime = false
    vase.packetBank = "Original"
    characterNode.add_child(vase)
