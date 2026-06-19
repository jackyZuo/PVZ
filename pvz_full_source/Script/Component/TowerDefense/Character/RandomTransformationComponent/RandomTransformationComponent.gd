
class_name RandomTransformationComponent extends ComponentBase


var parent: TowerDefenseCharacter


@export var includePacketBankList: Array[RandomTransformationComponentPacketBankConfig]:
    set(_includePacketBankList):
        includePacketBankList = _includePacketBankList


@export var excludePacketBankList: Array[RandomTransformationComponentPacketBankConfig]:
    set(_excludePacketBankList):
        excludePacketBankList = _excludePacketBankList


@export var includePacketNameList: Array[String]:
    set(_includePacketNameList):
        includePacketNameList = _includePacketNameList


@export var excludePacketNameList: Array[String]:
    set(_excludePacketNameList):
        excludePacketNameList = _excludePacketNameList



var packetList: Array = []


func GetName() -> String:
    return "RandomTransformationComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    if !is_instance_valid(parent):
        return


func Refresh() -> void :
    packetList.clear()
    packetList.append_array(includePacketNameList)
    for include: RandomTransformationComponentPacketBankConfig in includePacketBankList:
        packetList.append_array(include.GetPacketList())
    for exclude: RandomTransformationComponentPacketBankConfig in excludePacketBankList:
        for packetName: String in exclude.GetPacketList():
            packetList.erase(packetName)
    for packetName: String in excludePacketNameList:
        packetList.erase(packetName)



func GetRandPacketName() -> String:
    if packetList.size() <= 0:
        return ""
    return packetList.pick_random()
