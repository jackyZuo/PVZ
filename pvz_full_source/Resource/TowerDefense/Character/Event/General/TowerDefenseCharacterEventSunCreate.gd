class_name TowerDefenseCharacterEventSunCreate extends TowerDefenseCharacterEventBase

@export var num: float = 25.0
@export var dieCreate: bool = false
@export var mustForzen: bool = false
@export var fromPacket: bool = false
@export var fromPacketPercentage: float = 1.0
@export var byCamp: bool = false

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, num, dieCreate, mustForzen, fromPacket, fromPacketPercentage, byCamp)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, num * delta, dieCreate, mustForzen, fromPacket, fromPacketPercentage, byCamp)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, num, dieCreate, mustForzen, fromPacket, fromPacketPercentage, byCamp)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    num = valueDictionary.get("Num", 50.0)
    dieCreate = valueDictionary.get("DieCreate", false)
    mustForzen = valueDictionary.get("MustForzen", false)
    fromPacket = valueDictionary.get("FromPacket", false)
    fromPacketPercentage = valueDictionary.get("FromPacketPercentage", 1.0)
    byCamp = valueDictionary.get("ByCamp", false)

func Export() -> Dictionary:
    return {
        "EventName": "SunCreate", 
        "Value": {
            "Num": num, 
            "DieCreate": dieCreate, 
            "MustForzen": mustForzen, 
            "FromPacket": fromPacket, 
            "FromPacketPercentage": fromPacketPercentage, 
            "ByCamp": byCamp
        }
    }

static func Run(target: TowerDefenseCharacter, _num = 25.0, _dieCreate: bool = false, _mustForzen: bool = false, _fromPacket: bool = false, _fromPacketPercentage: float = 1.0, _byCamp: bool = false) -> void :
    if _dieCreate:
        if !target.IsDie():
            return
    if _mustForzen:
        if !target.buff.BuffHas("Frozen"):
            return
    if _byCamp:
        if target.camp != TowerDefenseEnum.CHARACTER_CAMP.PLANT:
            if !_fromPacket:
                target.SunCreate(target.global_position, _num, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            else:
                target.SunCreate(target.global_position, floor(target.packet.GetCost() * _fromPacketPercentage), TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
        else:
            if !_fromPacket:
                target.BrainSunCreate(target.global_position, _num, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            else:
                target.BrainSunCreate(target.global_position, floor(target.packet.GetCost() * _fromPacketPercentage), TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
    else:
        if !_fromPacket:
            target.SunCreate(target.global_position, _num, TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
        else:
            target.SunCreate(target.global_position, floor(target.packet.GetCost() * _fromPacketPercentage), TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
