@tool
class_name CharacterArmorData extends Resource

const REGISTRY_JSON: JSON = preload("res://Registry/Armor/ArmorRegistry.json")

@export var armorList: Array[ArmorSlotConfig]:
    set(_armorList):
        armorList = _armorList
        for config: ArmorSlotConfig in armorList:
            if !config.changed.is_connected(Init):
                config.changed.connect(Init)
        Init()

@export var armorDictionary: Dictionary = {}
@export var fliterAllDictionary: Dictionary = {}
@export var fliterOpenDictionary: Dictionary = {}
@export var fliterCloseDictionary: Dictionary = {}

static func _LoadTypeDataFromJSON(armorName: String) -> TowerDefenseArmorTypeData:
    var data: Dictionary = REGISTRY_JSON.data
    var armors: Dictionary = data.get("Armors", {})
    if armors.has(armorName):
        return load(armors[armorName]) as TowerDefenseArmorTypeData
    return null

func Init() -> void :
    fliterAllDictionary = {}
    armorDictionary = {}
    fliterOpenDictionary = {}
    fliterCloseDictionary = {}
    for slotConfig: ArmorSlotConfig in armorList:
        if slotConfig:
            var typeData: TowerDefenseArmorTypeData = _LoadTypeDataFromJSON(slotConfig.armorName)
            armorDictionary[slotConfig.armorName] = {"slotConfig": slotConfig, "typeData": typeData}
            var emptyFliter: Array[String] = []
            fliterAllDictionary[slotConfig.armorName] = emptyFliter.duplicate()
            var fliterGet: Array[String] = Array(Array(slotConfig.destroyFliter.split("&", false)), TYPE_STRING, "", null)
            if !fliterGet.is_empty():
                fliterAllDictionary[slotConfig.armorName].append_array(fliterGet)

            fliterOpenDictionary[slotConfig.armorName] = emptyFliter.duplicate()
            var fliterOpenGet: Array[String] = Array(Array(slotConfig.openFliter.split("&", false)), TYPE_STRING, "", null)
            if !fliterOpenGet.is_empty():
                fliterOpenDictionary[slotConfig.armorName].append_array(fliterOpenGet)

            fliterCloseDictionary[slotConfig.armorName] = emptyFliter.duplicate()
            var fliterCloseGet: Array[String] = Array(Array(slotConfig.closeFliter.split("&", false)), TYPE_STRING, "", null)
            if !fliterCloseGet.is_empty():
                fliterCloseDictionary[slotConfig.armorName].append_array(fliterCloseGet)


func ClearArmorFlitersAll(sprite: AdobeAnimateSprite) -> void :
    for armorName: String in fliterAllDictionary.keys():
        ClearArmorFliters(sprite, armorName)

func ClearArmorFliters(sprite: AdobeAnimateSprite, armorName: String) -> void :
    sprite.SetFliters(fliterAllDictionary[armorName], false)
    sprite.SetFliters(fliterCloseDictionary[armorName], true)
    sprite.SetFliters(fliterOpenDictionary[armorName], false)

func OpenArmorFlitersAll(sprite: AdobeAnimateSprite) -> void :
    for armorName: String in fliterAllDictionary.keys():
        OpenArmorFliters(sprite, armorName)

func OpenArmorFliters(sprite: AdobeAnimateSprite, armorName: String) -> void :
    sprite.SetFliters(fliterAllDictionary[armorName], true)
    sprite.SetFliters(fliterCloseDictionary[armorName], false)
    sprite.SetFliters(fliterOpenDictionary[armorName], true)

func SetArmorReplace(sprite: AdobeAnimateSprite, armorName: String, stage: int) -> void :
    var slotConfig: ArmorSlotConfig = armorDictionary[armorName]["slotConfig"]
    var typeData: TowerDefenseArmorTypeData = armorDictionary[armorName]["typeData"]
    if typeData:
        var stageTexture = typeData.stageAnimeTexture
        if stageTexture.size() > 0:
            var replaceTexture: Texture2D = stageTexture[stage]
            sprite.SetReplace(slotConfig.replaceMediaName, replaceTexture)

func GetSlotConfig(armorName: String) -> ArmorSlotConfig:
    if armorDictionary.has(armorName):
        return armorDictionary[armorName]["slotConfig"]
    return null

func GetOrCreateSlotConfig(armorName: String) -> ArmorSlotConfig:
    if armorDictionary.has(armorName):
        return armorDictionary[armorName]["slotConfig"]
    var typeData: TowerDefenseArmorTypeData = _LoadTypeDataFromJSON(armorName)
    if !typeData:
        return null
    var slotConfig: ArmorSlotConfig = ArmorSlotConfig.new()
    slotConfig.armorName = armorName
    slotConfig.replaceMethod = "Sprite"
    slotConfig.slotPath = NodePath("HeadSlot")
    slotConfig.offset = Vector2.ZERO
    slotConfig.rotation = 0.0
    slotConfig.scale = Vector2.ONE
    slotConfig.damagePoint = -1.0
    slotConfig.openFliter = ""
    slotConfig.closeFliter = ""
    slotConfig.destroyFliter = ""
    armorDictionary[armorName] = {"slotConfig": slotConfig, "typeData": typeData}
    var emptyFliter: Array[String] = []
    fliterAllDictionary[armorName] = emptyFliter.duplicate()
    var fliterGet: Array[String] = Array(Array(slotConfig.destroyFliter.split("&", false)), TYPE_STRING, "", null)
    if !fliterGet.is_empty():
        fliterAllDictionary[armorName].append_array(fliterGet)
    fliterOpenDictionary[armorName] = emptyFliter.duplicate()
    var fliterOpenGet: Array[String] = Array(Array(slotConfig.openFliter.split("&", false)), TYPE_STRING, "", null)
    if !fliterOpenGet.is_empty():
        fliterOpenDictionary[armorName].append_array(fliterOpenGet)
    fliterCloseDictionary[armorName] = emptyFliter.duplicate()
    var fliterCloseGet: Array[String] = Array(Array(slotConfig.closeFliter.split("&", false)), TYPE_STRING, "", null)
    if !fliterCloseGet.is_empty():
        fliterCloseDictionary[armorName].append_array(fliterCloseGet)
    return slotConfig

func GetTypeData(armorName: String) -> TowerDefenseArmorTypeData:
    if armorDictionary.has(armorName):
        return armorDictionary[armorName]["typeData"]
    return null
