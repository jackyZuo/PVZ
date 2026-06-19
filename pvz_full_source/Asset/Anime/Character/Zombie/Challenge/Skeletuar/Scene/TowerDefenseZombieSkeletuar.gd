@tool
extends TowerDefenseZombieGargantuarBase

var over: bool = false

const ZOMBIE_SKELETUAR_HEAD_2 = preload("uid://c4pcthsh66g7r")

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if over:
        await get_tree().physics_frame
        sprite.SetAnimation("Relife", false, 0.2)
        impThrowDamagePointName = ""
        ImpFliterSet()
    if TowerDefenseManager.MapLineHasType(gridPos.y, TowerDefenseEnum.PLANTGRIDTYPE.WATER):
        sprite.SetFliter("Zombie_duckytube", true)

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Head":
            sprite.SetReplace("Zombie_Skeletuar_head.png", ZOMBIE_SKELETUAR_HEAD_2)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Relife":
            Walk()
    if dieAnimeClip.split("&", false).has(clip):
        if inWater:
            return
        if over:
            return
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            over = true
            await get_tree().physics_frame
            Destroy()
            return
        over = true
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("Skeleton")
        var Skeleton = packetConfig.Create(global_position, gridPos, 0)
        characterNode.add_child(Skeleton)
        var _hitpointScale: float = instance.hitpointScale
        var _scale: Vector2 = transformPoint.scale
        ( func():
            if is_instance_valid(Skeleton):
                if is_instance_valid(Skeleton.instance):
                    Skeleton.instance.hitpointScale = _hitpointScale
                if is_instance_valid(Skeleton.transformPoint):
                    Skeleton.transformPoint.scale = _scale).call_deferred()
        Skeleton.set_deferred("invisible", invisible)
        await get_tree().physics_frame
        Destroy()
        return

func InWater() -> void :
    super.InWater()
    sprite.SetFliter("Zombie_whitewater", true)

func OutWater() -> void :
    super.OutWater()
    sprite.SetFliter("Zombie_whitewater", false)
