class_name ArmorVisualComponent extends ComponentBase

var parent: TowerDefenseCharacter

func GetName() -> String:
    return "ArmorVisualComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func ClearArmor(armor: String) -> void :
    parent.config.armorData.ClearArmorFliters(parent.sprite, armor)

func ClearArmorAll() -> void :
    parent.config.armorData.ClearArmorFlitersAll(parent.sprite)

func SetArmor(armor: String, stage: int) -> void :
    ClearArmor(armor)
    parent.config.armorData.OpenArmorFliters(parent.sprite, armor)
    parent.config.armorData.SetArmorReplace(parent.sprite, armor, stage)

func SetArmors(armorList: Array[String]) -> void :
    ClearArmorAll()
    for armor: String in armorList:
        if armor != "":
            SetArmor(armor, 0)
