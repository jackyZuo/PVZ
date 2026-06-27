
class_name ProduceComponent extends ComponentBase


@onready var light: Array[PointLight2D] = [ %Light, %Light2]


@export var _IZMMode: bool = false

@export_enum("Sun", "BrainSun", "JalaSun", "Coin", "Packet") var produceType: String = "Sun"

@export var produceInterval: float = 25.0

@export var num: int = 25

@export var sunOnceMax: int = 50

@export var marker: Array[Marker2D]

@export var onlyEmit: bool = false

@export var coinRandom: bool = true

@export var packetName: Array[String]


signal product(pos: int, _num: int)


var timer: float = 0.0

var produceGlowStarted: bool = false


var parent: TowerDefenseCharacter


var currentTarget: TowerDefenseCharacter


var hpNext: float = 0

var hpNextInterval: float = 50


var isBaseIZM: bool = false

var _sync_last_coin_value: int = -1
var _sync_last_packet_name: String = ""
var _sync_deserializing: bool = false


func GetName() -> String:
    return "ProduceComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return
    parent.destroy.connect(Destroy)
    timer = produceInterval - randf_range(3.0, 6.0)
    await get_tree().physics_frame
    hpNextInterval = parent.instance.hitpoints / 6.0
    hpNext = parent.instance.hitpoints - hpNextInterval

    if TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode():
        isBaseIZM = true
        _IZMMode = true


func _physics_process(delta: float) -> void :
    if !alive || !is_instance_valid(parent):
        return
    if !parent:
        return
    if parent.die || parent.nearDie:
        return
    if parent.instance.sleep:
        return
    if !parent.componentAlive:
        return
    if TowerDefenseManager.currentControl && !TowerDefenseManager.currentControl.isGameRunning:
        return
    for i in marker.size():
        if is_instance_valid(light[i]) && is_instance_valid(marker[i]):
            light[i].global_position = marker[i].global_position
    var useProductFlag: bool = true
    if parent is TowerDefensePlant && _IZMMode:
        useProductFlag = false
    var runScale: float = 1.0
    if parent.buff.BuffHas("TabooBean"):
        runScale *= 3.0
    if useProductFlag:
        if timer > produceInterval:
            timer -= produceInterval
            if !produceGlowStarted:
                _StartProduceGlow()
            produceGlowStarted = false
            if TowerDefenseManager.currentControl && !TowerDefenseManager.currentControl.isGameRunning:
                return
            if marker.size() > 0:
                for i in marker.size():
                    if is_instance_valid(marker[i]):
                        if !onlyEmit:
                            Create(marker[i].global_position, num)
                        product.emit(i, num)
            else:
                if !onlyEmit:
                    Create(parent.global_position, num)
                product.emit(-1, num)
        else:
            timer += delta * runScale
            if !produceGlowStarted && timer >= produceInterval - 1.5:
                _StartProduceGlow()
                produceGlowStarted = true
    elif parent is TowerDefensePlant && _IZMMode:
        while (parent.instance.hitpoints <= hpNext):
            hpNext -= hpNextInterval
            if marker.size() > 0:
                for i in marker.size():
                    if !onlyEmit:
                        Create(marker[i].global_position, num)
                    product.emit(i, num)
            else:
                if !onlyEmit:
                    Create(parent.global_position, num)
                product.emit(-1, num)

func _StartProduceGlow() -> void :
    if TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect"):
        for i in marker.size():
            light[i].visible = true
            var _light = light[i]
            var tween = create_tween()
            tween.tween_property(light[i], ^"energy", 1.0, 1.5).from(0.0)
            tween.tween_property(light[i], ^"energy", 0.0, 0.5).from(1.0)
            tween.finished.connect(
                func():
                    if is_instance_valid(_light):
                        _light.visible = false
            )
    parent.Bright(0.0, 0.0, 0.5, 1.5, 0.5)




func Create(pos: Vector2, _num: int) -> void :
    var createNum: int = _num
    match produceType:
        "Sun":
            if !isBaseIZM && !(parent is TowerDefensePlant && parent.instance.hypnoses):
                while (createNum > sunOnceMax):
                    parent.SunCreate(pos, sunOnceMax)
                    createNum -= sunOnceMax
                parent.SunCreate(pos, createNum)
            else:
                while (createNum > sunOnceMax):
                    parent.BrainSunCreate(pos, sunOnceMax)
                    createNum -= sunOnceMax
                parent.BrainSunCreate(pos, createNum)
        "BrainSun":
            while (createNum > sunOnceMax):
                parent.BrainSunCreate(pos, sunOnceMax)
                createNum -= sunOnceMax
            parent.BrainSunCreate(pos, createNum)
        "JalaSun":
            while (createNum > sunOnceMax):
                parent.JalapenoSunCreate(pos, sunOnceMax)
                createNum -= sunOnceMax
            parent.JalapenoSunCreate(pos, createNum)
        "Coin":
            if coinRandom:
                var _randomNum: int = 10
                if _sync_deserializing and _sync_last_coin_value >= 0:
                    _randomNum = _sync_last_coin_value
                    _sync_last_coin_value = -1
                    _sync_deserializing = false
                else:
                    if randf() < 0.02:
                        _randomNum = 1000
                    elif randf() < 0.2:
                        _randomNum = 50
                    _sync_last_coin_value = _randomNum
                parent.CoinCreate(pos, _randomNum)
            else:
                parent.CoinCreate(pos, createNum)
        "Packet":
            var picked_name: String = ""
            if _sync_deserializing and _sync_last_packet_name != "":
                picked_name = _sync_last_packet_name
                _sync_last_packet_name = ""
                _sync_deserializing = false
            else:
                picked_name = packetName.pick_random()
                _sync_last_packet_name = picked_name
            var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(picked_name)
            if parent.instance.hypnoses:
                packetConfig.overrideHypnoses = true
            parent.SpawnPacket(packetConfig, pos, 15.0, false)


@warning_ignore("unused_parameter")
func Destroy(character: TowerDefenseCharacter) -> void :
    if character.isShovel:
        return
    if parent.instance.sleep:
        return
    if !parent.componentAlive:
        return
    if !parent.die:
        return
    if parent is TowerDefensePlant && (TowerDefenseManager.IsIZMMode() || TowerDefenseManager.IsIZM2Mode() || _IZMMode):
        while (hpNext >= 0):
            hpNext -= hpNextInterval
            if marker.size() > 0:
                for i in marker.size():
                    Create(marker[i].global_position, num)
            else:
                Create(parent.global_position, num)


func ImmediateProduct() -> void :
    timer = produceInterval

func ExportComponentSave() -> Dictionary:
    return {
        "timer": timer, 
        "hpNext": hpNext, 
        "hpNextInterval": hpNextInterval, 
        "produceType": produceType, 
    }

func ImportComponentSave(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    timer = _data.get("timer", 0.0)
    hpNext = _data.get("hpNext", -1.0)
    hpNextInterval = _data.get("hpNextInterval", 0.0)
    produceType = _data.get("produceType", produceType)

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {
        "timer": timer, 
        "hpNext": hpNext, 
        "hpNextInterval": hpNextInterval, 
        "produceGlowStarted": produceGlowStarted, 
    }
    if _sync_last_coin_value >= 0:
        data["last_coin_value"] = _sync_last_coin_value
    if _sync_last_packet_name != "":
        data["last_packet_name"] = _sync_last_packet_name
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    timer = _data.get("timer", timer)
    hpNext = _data.get("hpNext", hpNext)
    hpNextInterval = _data.get("hpNextInterval", hpNextInterval)
    produceGlowStarted = _data.get("produceGlowStarted", produceGlowStarted)
    if _data.has("last_coin_value"):
        _sync_last_coin_value = _data.get("last_coin_value", -1)
        _sync_deserializing = true
    if _data.has("last_packet_name"):
        _sync_last_packet_name = _data.get("last_packet_name", "")
        _sync_deserializing = true
