class_name TowerDefenseBattleFeatureScreenEffect extends TowerDefenseBattleFeature

const SCREEN_EFFECT_CONTROL = preload("uid://cn2idxrgpsjc5")

static var EFFECT: Dictionary = {
    "Rain": preload("uid://brduo5wtglu0"), 
    "Storm": preload("uid://qha0env3257g")
}

var screenEffectControl
var currentEffect: Dictionary = {}



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    screenEffectControl = SCREEN_EFFECT_CONTROL.instantiate()
    control.AddUI(screenEffectControl, 10)
    var stormOpen: bool = data.get("StormOpen", false)
    var packetBankMethod: int = data.get("PacketBankMethod", -1)
    if stormOpen:
        AddScreenEffect("Rain")
        AddScreenEffect("Storm")
    if packetBankMethod == TowerDefenseEnum.LEVEL_SEEDBANK_METHOD.RAIN:
        AddScreenEffect("Rain")



func AddScreenEffect(effectName: String) -> void :
    if currentEffect.has(effectName):
        return
    if !EFFECT.has(effectName):
        return
    currentEffect[effectName] = EFFECT[effectName].instantiate()
    screenEffectControl.add_child(currentEffect[effectName])

func DeleteScreenEffect(effectName: String) -> void :
    if !currentEffect.has(effectName):
        return
    if is_instance_valid(currentEffect[effectName]):
        currentEffect[effectName].queue_free()
        currentEffect.erase(effectName)

func GetScreenEffect(effectName: String) -> Node:
    if !currentEffect.has(effectName):
        return null
    return currentEffect[effectName]

func HasScreenEffect(effectName: String) -> bool:
    return currentEffect.has(effectName)
