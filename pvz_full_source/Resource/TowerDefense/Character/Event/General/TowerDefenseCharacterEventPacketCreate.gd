class_name TowerDefenseCharacterEventPacketCreate extends TowerDefenseCharacterEventBase

@export var usePacketBank: bool = false
@export var packetName: String = ""
@export var packetBankName: String = "GeneralPlant"
@export var categoryName: String = ""
@export var aliveTime: float = 15.0
@export var useCost: bool = false
@export var override: TowerDefensePacketOverride

@warning_ignore("unused_parameter")
func Execute(pos: Vector2, target: TowerDefenseCharacter) -> void :
    Run(target, usePacketBank, packetName, packetBankName, categoryName, aliveTime, useCost, override)

@warning_ignore("unused_parameter")
func ExecuteDps(pos: Vector2, target: TowerDefenseCharacter, delta: float) -> void :
    Run(target, usePacketBank, packetName, packetBankName, categoryName, aliveTime, useCost, override)

@warning_ignore("unused_parameter")
func ExecuteProject(projectile: TowerDefenseProjectile, target: TowerDefenseCharacter) -> void :
    Run(target, usePacketBank, packetName, packetBankName, categoryName, aliveTime, useCost, override)

@warning_ignore("unused_parameter")
func Init(valueDictionary: Dictionary) -> void :
    usePacketBank = valueDictionary.get("UsePacketBank", false)
    packetName = valueDictionary.get("PacketName", "")
    packetBankName = valueDictionary.get("PacketBankName", "GeneralPlant")
    categoryName = valueDictionary.get("CategoryName", "")
    aliveTime = valueDictionary.get("AliveTime", 15.0)
    useCost = valueDictionary.get("UseCost", false)
    var overrideData: Dictionary = valueDictionary.get("Override", {})
    if !overrideData.is_empty():
        override = TowerDefensePacketOverride.new()
        override.Init(overrideData)


func Export() -> Dictionary:
    var data = {
        "EventName": "PacketCreate", 
        "Value": {
            "PacketName": packetName, 
            "PacketBankName": packetBankName, 
            "CategoryName": categoryName, 
            "UsePacketBank": usePacketBank, 
            "AliveTime": aliveTime, 
            "UseCost": useCost
        }
    }
    if is_instance_valid(override):
        data["Value"]["Override"] = override.Export()
    return data

static func Run(target: TowerDefenseCharacter, _usePacketBank: bool, _packetName: String, _packetBankName: String, _categoryName: String, _aliveTime: float = 8, _useCost: bool = false, _override: TowerDefensePacketOverride = null) -> void :
    var finalPacketName: String
    if _usePacketBank:
        var packetBank: TowerDefensePacketBankData = TowerDefenseManager.GetPacketBankData(_packetBankName)
        var packetList: Array
        if _categoryName != "":
            packetList = packetBank.GetCategory(_categoryName)
        else:
            packetList = packetBank.GetPacketList()
        finalPacketName = packetList[randi() % packetList.size()]
    else:
        finalPacketName = _packetName
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(finalPacketName)
    if is_instance_valid(_override):
        packetConfig.override = _override
    TowerDefenseManager.SpawnPacket(packetConfig, target.global_position, _aliveTime, false, _useCost, true)
    var packet: TowerDefenseInGamePacketShow = TowerDefenseManager.CreatePacketShow()
    packet.showCost = _useCost
    packet.aliveTime = _aliveTime
