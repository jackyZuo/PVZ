@tool
extends TowerDefenseZombie

var over: bool = false

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func DieEntered() -> void :
    super.DieEntered()
    DestroySet()

func DestroySet() -> void :
    if over:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        over = true
        return
    over = true
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieShadowBlack")
    var shadow = packetConfig.Create(global_position, gridPos, 0)
    characterNode.add_child.call_deferred(shadow)
    if instance.hypnoses:
        shadow.Hypnoses.call_deferred()
    var _hitpointScale: float = instance.hitpointScale
    var _scale: Vector2 = transformPoint.scale
    ( func():
        if is_instance_valid(shadow):
            if is_instance_valid(shadow.instance):
                shadow.instance.hitpointScale = _hitpointScale
            if is_instance_valid(shadow.transformPoint):
                shadow.transformPoint.scale = _scale).call_deferred()
    shadow.invisible = invisible
    await get_tree().physics_frame
