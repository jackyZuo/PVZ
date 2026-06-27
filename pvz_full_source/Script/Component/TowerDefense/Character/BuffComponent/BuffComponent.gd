
class_name BuffComponent extends ComponentBase


signal buffAdd(key: String)

signal buffDelete(key: String)


var parent: TowerDefenseCharacter


@export var buffDictionary: Dictionary[String, TowerDefenseCharacterBuffConfig]


var over: bool = false
var is_syncing: bool = false


func GetName() -> String:
    return "BuffComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !parent.is_node_ready():
        await parent.ready
    await get_tree().physics_frame
    parent.instance.hitpointsNearDie.connect(Destroy)
    parent.instance.hitpointsEmpty.connect(Destroy)



func BuffUpdate(delta: float) -> void :
    if !alive || buffDictionary.is_empty():
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        for buffKey: String in buffDictionary:
            var buff: TowerDefenseCharacterBuffConfig = buffDictionary[buffKey]
            buff.Step(delta)
        return
    var keys_to_delete: Array[String] = []
    for buffKey: String in buffDictionary:
        var buff: TowerDefenseCharacterBuffConfig = buffDictionary[buffKey]
        if buff.Step(delta):
            keys_to_delete.append(buffKey)
    for key in keys_to_delete:
        BuffDelete(key)




func BuffHas(key: String) -> bool:
    return buffDictionary.has(key)




func BuffGet(key: String) -> TowerDefenseCharacterBuffConfig:
    if BuffHas(key):
        return buffDictionary[key]
    return null



func BuffAdd(buffConfig: TowerDefenseCharacterBuffConfig) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and !is_syncing:
        return
    if buffConfig.refresh && BuffHas(buffConfig.key):
        buffDictionary[buffConfig.key].Refresh(buffConfig)
    else:
        buffDictionary[buffConfig.key] = buffConfig

    buffDictionary[buffConfig.key].character = parent
    buffDictionary[buffConfig.key].Enter()
    buffAdd.emit(buffConfig.key)



func BuffDelete(key: String) -> void :
    if !BuffHas(key):
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and !is_syncing:
        return
    var buff: TowerDefenseCharacterBuffConfig = buffDictionary[key]
    buff.Exit()
    buffDictionary.erase(key)
    buffDelete.emit(key)


func BuffClear() -> void :
    for key in buffDictionary.keys():
        BuffDelete(key)


func Destroy() -> void :
    if over:
        return
    over = true
    for buffKey: String in buffDictionary:
        var buff: TowerDefenseCharacterBuffConfig = buffDictionary[buffKey]
        if !(Global.isMultiplayerMode and !MultiPlayerManager.isHost):
            buff.Destroy()




func SetAttackNum(num: float) -> float:
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return num
    for buffKey: String in buffDictionary:
        var buff: TowerDefenseCharacterBuffConfig = buffDictionary[buffKey]
        num = buff.SetAttackNum(num)
    return num

const BUFF_SAVE_FIELDS: Dictionary = {
    "Frozen": ["time", "iceSpeedDownTime", "currentTime"], 
    "Burn": ["time", "dpsAttack", "splatInterval", "currentTime", "splatTime"], 
    "Hypnoses": ["time", "currentTime", "saveCamp"], 
    "IceSpeedDown": ["time", "currentTime"], 
    "Dizziness": ["time", "currentTime"], 
    "Butter": ["time", "currentTime"], 
    "Cherry": ["time", "currentTime"], 
    "Pogo": ["time", "currentTime"], 
    "Sleep": ["time", "currentTime"], 
    "FireHit": [], 
    "RedHeat": ["time", "currentTime"], 
    "Poisoning": ["time", "currentTime", "timer"], 
    "Fluorescence": ["time", "currentTime"], 
    "NormalHit": [], 
    "Squid": ["time", "currentTime"], 
    "TabooBean": ["time", "currentTime", "blink"], 
    "Coffee": ["timeScaleValue", "time", "currentTime", "blink"], 
}

func ExportSave() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for buffKey: String in buffDictionary:
        var buff: TowerDefenseCharacterBuffConfig = buffDictionary[buffKey]
        var data: Dictionary = {"key": buffKey}
        var fields: Array = BUFF_SAVE_FIELDS.get(buffKey, [])
        for field: String in fields:
            data[field] = buff.get(field)
        result.append(data)
    return result

func ImportSave(data: Array[Dictionary]) -> void :
    for buffData: Dictionary in data:
        var buffKey: String = buffData.get("key", "")
        if buffKey == "":
            continue
        var buff: TowerDefenseCharacterBuffConfig = TowerDefenseCharacterBuffConfig.CreateBuffByKey(buffKey)
        if buff == null:
            continue
        buff.character = parent
        buff.Enter()
        var fields: Array = BUFF_SAVE_FIELDS.get(buffKey, [])
        for field: String in fields:
            if buffData.has(field):
                buff.set(field, buffData[field])



        if buff is TowerDefenseCharacterBuffHypnoses:
            var hypnosesBuff: TowerDefenseCharacterBuffHypnoses = buff as TowerDefenseCharacterBuffHypnoses
            if hypnosesBuff.saveCamp != TowerDefenseEnum.CHARACTER_CAMP.NOONE:
                if hypnosesBuff.saveCamp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
                    parent.camp = TowerDefenseEnum.CHARACTER_CAMP.PLANT
                elif hypnosesBuff.saveCamp == TowerDefenseEnum.CHARACTER_CAMP.PLANT:
                    parent.camp = TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE
        buffDictionary[buff.key] = buff
        buffAdd.emit(buff.key)
