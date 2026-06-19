class_name VaseContentComponent extends ComponentBase

var parent: TowerDefenseVase

var _break_content_type: String = "none"
var _break_content_name: String = ""
var _break_packet_show_data: Dictionary = {}
var _break_zombie_sync_id: int = -1

func GetName() -> String:
    return "VaseContentComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func SetContent(_contentName: String) -> void :
    parent.packetName = _contentName

func DestroySet() -> void :
    if parent.over:
        return
    parent.over = true
    if is_instance_valid(TowerDefenseInGameLevelControl.instance):
        TowerDefenseInGameLevelControl.instance.hasSpawn = true
    AudioManager.AudioPlay("VaseBreaking", AudioManagerEnum.TYPE.SFX)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(parent.chunkParticles, parent.gridPos)
    effect.global_position = parent.transformPoint.global_position - Vector2(0, 30.0)
    TowerDefenseGroundItemBase.characterNode.add_child(effect)

    _break_content_type = "none"
    _break_content_name = ""
    _break_packet_show_data = {}
    _break_zombie_sync_id = -1

    if !is_instance_valid(parent.packetConfig):
        var packetBankData: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData(parent.packetBank)
        if is_instance_valid(packetBankData):
            var packetList: Array = packetBankData.GetPacketList()
            var packetRandom: String = packetList.pick_random()
            var _packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
            if !is_instance_valid(parent.cell):
                while packetList.size() > 1 && !_packetConfig.characterConfig is TowerDefensePlantConfig:
                    packetList.erase(packetRandom)
                    packetRandom = packetList.pick_random()
                    _packetConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
            if _packetConfig.characterConfig is TowerDefenseZombieConfig || _packetConfig.characterConfig is TowerDefenseGravestoneConfig || _packetConfig.characterConfig is TowerDefenseCraterConfig:
                if is_instance_valid(parent.cell):
                    while !parent.cell.CanPacketPlant(_packetConfig) && packetList.size() > 1:
                        packetList.erase(packetRandom)
                        packetRandom = packetList.pick_random()
                        _packetConfig = TowerDefenseManager.GetPacketConfig(packetRandom)
                    if packetList.size() > 1:
                        _break_content_type = "zombie"
                        _break_content_name = _packetConfig.saveKey
                        var zombie = _packetConfig.Plant(parent.gridPos, true)
                        zombie.instance.wakeUp = true
                        zombie.groundHeight = parent.groundHeight
                        if parent.instance.hypnoses:
                            zombie.Hypnoses()
                        _register_multiplayer_zombie(zombie)
            else:
                _break_content_type = "plant"
                _break_content_name = _packetConfig.saveKey
                CreatePacketShow(_packetConfig)
    else:
        if parent.packetConfig.characterConfig is TowerDefenseZombieConfig || parent.packetConfig.characterConfig is TowerDefenseGravestoneConfig || parent.packetConfig.characterConfig is TowerDefenseCraterConfig:
            _break_content_type = "zombie"
            _break_content_name = parent.packetConfig.saveKey
            var zombie = parent.packetConfig.Plant(parent.gridPos, true)
            zombie.instance.wakeUp = true
            zombie.groundHeight = parent.groundHeight
            if parent.instance.hypnoses:
                zombie.Hypnoses()
            _register_multiplayer_zombie(zombie)
        else:
            _break_content_type = "plant"
            _break_content_name = parent.packetConfig.saveKey
            CreatePacketShow(parent.packetConfig)

    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var break_data: Dictionary = {
            "grid_x": parent.gridPos.x, 
            "grid_y": parent.gridPos.y, 
            "content_type": _break_content_type, 
            "content_name": _break_content_name, 
            "ground_height": parent.groundHeight, 
            "hypnoses": parent.instance.hypnoses if is_instance_valid(parent.instance) else false, 
        }
        if _break_content_type == "zombie":
            if _break_zombie_sync_id >= 0:
                break_data["sync_id"] = _break_zombie_sync_id
        if _break_content_type == "plant" and !_break_packet_show_data.is_empty():
            break_data["packet_show"] = _break_packet_show_data
        MultiPlayerManager.SendVaseBreakResult(break_data)

    await parent.get_tree().physics_frame

func _register_multiplayer_zombie(zombie: TowerDefenseCharacter) -> void :
    if !Global.isMultiplayerMode or !MultiPlayerManager.isHost:
        return
    if !is_instance_valid(zombie):
        return
    var control = TowerDefenseManager.currentControl
    if !is_instance_valid(control):
        return
    var _sync_id: int = control._get_next_sync_id()
    control._register_sync_character(_sync_id, zombie)
    _break_zombie_sync_id = _sync_id

func CreatePacketShow(_packetConfig: TowerDefensePacketConfig) -> void :
    var velocityX: float = randf_range(-50, -30) if randf() > 0.5 else randf_range(30, 50)
    var velocityY: float = -300.0
    var packetInstance: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packetInstance.z_index = parent.z_index
    packetInstance.global_position = parent.global_position + Vector2(0, - parent.groundHeight)
    TowerDefenseGroundItemBase.characterNode.add_child(packetInstance)
    packetInstance.Init(_packetConfig)
    packetInstance.onlyDraw = false
    packetInstance.showCost = false
    packetInstance.useCost = false
    packetInstance.plantOnce = true
    packetInstance.canPressPutBack = false
    packetInstance.StartInit()
    packetInstance.alive = true
    packetInstance.aliveTime = 15.0
    packetInstance.height = 0
    packetInstance.moveComponent.gravity = 980.0
    packetInstance.moveComponent.velocity = Vector2(velocityX, velocityY)
    var packetPickControl: PacketPickControl = TowerDefenseManager.GetPacketPickControl()
    if is_instance_valid(packetPickControl):
        packetInstance.pressed.connect(packetPickControl.PickPacket)
    packetInstance.add_to_group("VasePacketShow")

    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var sync_id: int = control._get_next_packet_sync_id()
            packetInstance.set_meta("packet_sync_id", sync_id)
            control._register_sync_packet(sync_id, packetInstance)
            _break_packet_show_data = {
                "packet_name": _packetConfig.saveKey, 
                "pos_x": packetInstance.global_position.x, 
                "pos_y": packetInstance.global_position.y, 
                "z_index": packetInstance.z_index, 
                "velocity_x": velocityX, 
                "velocity_y": velocityY, 
                "sync_id": sync_id
            }
