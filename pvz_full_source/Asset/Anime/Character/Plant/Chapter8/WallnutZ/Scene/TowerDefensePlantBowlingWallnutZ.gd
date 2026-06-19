@tool
extends TowerDefensePlantBowlingBase

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if config.customData:
        var packetValue: Dictionary = GameSaveManager.GetTowerDefensePacketValue("PlantWallnutZ")
        if packetValue.get_or_add("Key", {}).get_or_add("Custom", "") != "":
            currentCustom = [packetValue["Key"]["Custom"]]

func Bowling(character: TowerDefenseCharacter) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        Destroy()
        return
    var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieGargantuar")
    var spawn_pos: Vector2 = character.global_position
    var zombie: TowerDefenseZombie = zombiePacket.Create(spawn_pos, character.gridPos, 0.0)
    characterNode.add_child(zombie)
    if !instance.hypnoses:
        zombie.Hypnoses()
    zombie.state.process_mode = Node.PROCESS_MODE_DISABLED
    var tween = zombie.create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(zombie.transformPoint, ^"scale", Vector2.ONE, 0.5).from(Vector2.ONE * 0.5)
    tween.finished.connect(
        func():
            if is_instance_valid(zombie):
                zombie.Walk()
                zombie.state.process_mode = Node.PROCESS_MODE_INHERIT
    )
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt("ZombieGargantuar", character.gridPos.x, character.gridPos.y, _sync_id, 1.0, 1.0, !instance.hypnoses, 0.0, true, spawn_pos.x, spawn_pos.y, true)
    Destroy()
