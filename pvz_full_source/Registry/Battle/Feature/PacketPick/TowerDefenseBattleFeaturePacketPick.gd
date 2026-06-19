class_name TowerDefenseBattleFeaturePacketPick extends TowerDefenseBattleFeature

var packetPickControl: PacketPickControl

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    packetPickControl = PacketPickControl.new()

func GameInit() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    mapFeature.packetPickControl = packetPickControl
    packetPickControl.Init(mapControl, mapFeature)
    mapControl.add_child(packetPickControl)

func GameInitFromProgress() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    mapFeature.packetPickControl = packetPickControl
    packetPickControl.Init(mapControl, mapFeature)
    mapControl.add_child(packetPickControl)
