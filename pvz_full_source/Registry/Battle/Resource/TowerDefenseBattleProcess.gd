class_name TowerDefenseBattleProcess extends Resource

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

func InitManager() -> void :
    pass

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

@warning_ignore("unused_parameter")
func GameFail(enterCharacter: TowerDefenseCharacter) -> void :
    pass

@warning_ignore("unused_parameter")
func ZombieEnterHouse(character: TowerDefenseCharacter) -> void :
    pass

func ViewMap() -> void :
    pass

func CanLoadProgress() -> bool:
    return true

func CheckFinal() -> bool:
    return false

func CheckFail() -> bool:
    return false

func Finish() -> void :
    pass

@warning_ignore("unused_parameter")
func PhysicsProcess(delta: float) -> void :
    pass

@warning_ignore("unused_parameter")
func InputProcess(event: InputEvent) -> void :
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

func SaveProcess() -> Dictionary:
    return {}

@warning_ignore("unused_parameter")
func LoadProcess(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    pass

func GetTree() -> SceneTree:
    if control:
        return control.get_tree()
    return null

func GetFeature(featureName: StringName) -> TowerDefenseBattleFeature:
    if control:
        return control.GetFeature(featureName)
    return null

func GetLevelControl() -> TowerDefenseInGameLevelControl:
    if control:
        return control.levelControl
    return null
