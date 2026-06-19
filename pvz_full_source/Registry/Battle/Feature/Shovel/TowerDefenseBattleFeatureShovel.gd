class_name TowerDefenseBattleFeatureShovel extends TowerDefenseBattleFeature

const SHOVEL_MANAGER = preload("res://Registry/Battle/Feature/Shovel/ShovelManager/ShovelManager.tscn")

var shovelManager: ShovelManager
var shovelPickTool: ShovelPickTool

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    shovelManager = SHOVEL_MANAGER.instantiate()
    control.AddUIToTopPropContainer(shovelManager)

func GameInit() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    mapFeature.shovelManager = shovelManager
    shovelManager.Init(mapControl, mapFeature)

func GameInitFromProgress() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    mapFeature.shovelManager = shovelManager
    shovelManager.Init(mapControl, mapFeature)

func GameEntry() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.packetPickControl):
        shovelPickTool = ShovelPickTool.new()
        shovelPickTool.Init(mapControl)
        shovelPickTool.SetShovelManager(shovelManager)
        mapFeature.packetPickControl.RegisterTool(shovelPickTool)

func GameStart() -> void :
    if is_instance_valid(shovelManager):
        shovelManager.ShovelReset()
    if is_instance_valid(shovelPickTool):
        return
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    var mapControl: TowerDefenseMapControl = mapFeature.mapControl
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.packetPickControl):
        shovelPickTool = ShovelPickTool.new()
        shovelPickTool.Init(mapControl)
        shovelPickTool.SetShovelManager(shovelManager)
        mapFeature.packetPickControl.RegisterTool(shovelPickTool)
