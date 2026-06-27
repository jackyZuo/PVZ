class_name TowerDefenseArmorRegistry

const REGISTRY_JSON: JSON = preload("res://Registry/Armor/ArmorRegistry.json")

static var isInit: bool = false
static var armorDictionary: Dictionary[StringName, TowerDefenseArmorTypeData]

static func Init() -> void :
    if isInit:
        return
    isInit = true
    RegisterInit()

static func RegisterInit() -> void :
    var data: Dictionary = REGISTRY_JSON.data
    var armors: Dictionary = data.get("Armors", {})
    for armorName: String in armors:
        var armorTypeData = load(armors[armorName]) as TowerDefenseArmorTypeData
        if armorTypeData:
            RegisterArmor(armorName, armorTypeData)

static func RegisterArmor(armorName: StringName, armorTypeData: TowerDefenseArmorTypeData) -> void :
    armorDictionary[armorName] = armorTypeData

static func GetArmorType(armorName: StringName) -> TowerDefenseArmorTypeData:
    if !armorDictionary.has(armorName):
        return null
    return armorDictionary[armorName].duplicate()

static func HasArmor(armorName: StringName) -> bool:
    return armorDictionary.has(armorName)

static func GetArmorNames() -> Array[StringName]:
    var names: Array[StringName] = []
    for name: StringName in armorDictionary:
        names.append(name)
    return names
