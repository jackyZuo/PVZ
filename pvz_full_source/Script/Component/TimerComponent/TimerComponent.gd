
class_name TimerComponent extends ComponentBase


signal timeout(timerName: String)


@export var timerDictionary: Dictionary[String, float]

@export var timeScale: float = 1.0


var timerRunning: Dictionary[String, float]

var timerWaitTime: Dictionary[String, float]

var timerCurrent: Dictionary[String, float]


var parent: Node


func GetName() -> String:
    return "TimerComponent"


func _ready() -> void :
    parent = get_parent()
    for key in timerDictionary.keys():
        timerRunning[key] = false
        timerWaitTime[key] = timerDictionary[key]
        timerCurrent[key] = 0.0


func _physics_process(delta) -> void :
    if !alive:
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    for key: String in timerRunning.keys():
        if timerRunning[key]:
            if timerCurrent[key] < timerWaitTime[key]:
                timerCurrent[key] += delta * timeScale
            else:
                timerCurrent[key] = 0.0
                timerRunning[key] = false
                timeout.emit.call_deferred(key)




func AddTimer(timerName: String, time = 1.0) -> void :
    timerDictionary[timerName] = time
    timerRunning[timerName] = false
    timerWaitTime[timerName] = timerDictionary[timerName]
    timerCurrent[timerName] = 0.0




func Run(timerName: String, time: float = -1.0) -> void :
    if !timerDictionary.has(timerName):
        return
    timerWaitTime[timerName] = (timerDictionary[timerName] if time == -1.0 else time)
    timerCurrent[timerName] = 0.0
    timerRunning[timerName] = true



func Stop(timerName: String) -> void :
    if !timerDictionary.has(timerName):
        return
    timerCurrent[timerName] = 0.0
    timerRunning[timerName] = false




func IsRunning(timerName: String) -> bool:
    if !timerDictionary.has(timerName):
        return false
    return timerRunning[timerName]

func ExportComponentSave() -> Dictionary:
    var runningData: Dictionary = {}
    var waitTimeData: Dictionary = {}
    var currentData: Dictionary = {}
    for key: String in timerRunning.keys():
        runningData[key] = timerRunning[key]
        waitTimeData[key] = timerWaitTime.get(key, 0.0)
        currentData[key] = timerCurrent.get(key, 0.0)
    return {
        "timerRunning": runningData, 
        "timerWaitTime": waitTimeData, 
        "timerCurrent": currentData, 
        "timeScale": timeScale, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    var runningData: Dictionary = _data.get("timerRunning", {})
    var waitTimeData: Dictionary = _data.get("timerWaitTime", {})
    var currentData: Dictionary = _data.get("timerCurrent", {})
    timeScale = _data.get("timeScale", 1.0)
    for key: String in runningData.keys():
        timerRunning[key] = runningData[key]
    for key: String in waitTimeData.keys():
        timerWaitTime[key] = waitTimeData[key]
    for key: String in currentData.keys():
        timerCurrent[key] = currentData[key]
