class_name TowerDefenseBattleFeatureCamera extends TowerDefenseBattleFeature

const TOWER_DEFENSE_CAMERA_CONTROL = preload("uid://7i6bh10be5o0")

var cameraControl: TowerDefenseCameraControl



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    cameraControl = TOWER_DEFENSE_CAMERA_CONTROL.instantiate()
    control.AddNode(cameraControl)

func GameInit() -> void :
    var mapFeature: TowerDefenseBattleFeatureMap = GetFeature("Map")
    if is_instance_valid(mapFeature) && is_instance_valid(mapFeature.mapConfig):
        cameraControl.InitSize(mapFeature.mapConfig.mapSize)

func GameInitFromProgress() -> void :
    GameInit()
