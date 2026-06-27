class_name TowerDefenseBattleFeature extends Resource

var control: TowerDefenseControlNew
var data: Dictionary
var dependenceData: TowerDefenseBattleDependenceData

func Init(_data: Dictionary) -> void :
    data = _data

func Ready() -> void :
    pass

@warning_ignore("unused_parameter")
func Process(delta: float) -> void :
    pass

func CanLoadProgress() -> bool:
    return true

func GameInit() -> void :
    pass

func GameInitFromProgress() -> void :
    pass

func GameEntry() -> void :
    pass

func GameReady() -> void :
    pass

func GameStart() -> void :
    pass

func GameStartFromProgress() -> void :
    GameStart()

func GameFail() -> void :
    pass

func Destroy() -> void :
    pass

@warning_ignore("unused_parameter")
func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    pass

@warning_ignore("unused_parameter")
func SyncSerialize() -> Dictionary:
    return {}

@warning_ignore("unused_parameter", "shadowed_variable")
func SyncDeserialize(_data: Dictionary) -> void :
    pass

@warning_ignore("unused_parameter")
func SyncProcess(delta: float) -> void :
    pass

func SaveFeature() -> Dictionary:
    return {}

@warning_ignore("unused_parameter")
func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    pass

func GetFeature(featureName: StringName) -> TowerDefenseBattleFeature:
    return control.GetFeature(featureName)

func GetProcess() -> TowerDefenseBattleProcess:
    return control.process

func GetLevelControl() -> TowerDefenseInGameLevelControl:
    return control.levelControl

func GetTree() -> SceneTree:
    return control.get_tree()
