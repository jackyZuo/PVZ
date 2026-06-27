
class_name ShaderEffectComponent extends ComponentBase


const SHADER_EFFECT_FLAGS: Dictionary = {
    "ash": 1 << 0, 
    "iceSpeedDown": 1 << 1, 
    "cover": 1 << 2, 
    "hypnoses": 1 << 3, 
    "imitater": 1 << 4, 
    "redHeat": 1 << 5, 
    "puzzle": 1 << 6, 
    "poisoning": 1 << 7, 
    "blink": 1 << 8, 
    "hologram": 1 << 9
}


var parent: TowerDefenseCharacter


var _shaderNodes: Array[AdobeAnimateSpriteBase] = []


func GetName() -> String:
    return "ShaderEffectComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready


func Init() -> void :
    _shaderNodes.clear()
    _CollectShaderNodesRecursive(parent.sprite)



func _CollectShaderNodesRecursive(parentNode: Node2D) -> void :
    if parentNode is AdobeAnimateSpriteBase:
        _shaderNodes.append(parentNode)
    for child in parentNode.get_children():
        _CollectShaderNodesRecursive(child)




func SetSpriteGroupShaderParameter(property: String, value: Variant) -> void :
    if SHADER_EFFECT_FLAGS.has(property):
        var flag: int = SHADER_EFFECT_FLAGS[property]
        for node: AdobeAnimateSpriteBase in _shaderNodes:
            if !is_instance_valid(node):
                continue
            var current: int = node.get_instance_shader_parameter("effectFlags") if node.get_instance_shader_parameter("effectFlags") != null else 0
            if value:
                current |= flag
            else:
                current &= ~ flag
            node.set_instance_shader_parameter("effectFlags", current)
    else:
        for node: AdobeAnimateSpriteBase in _shaderNodes:
            if !is_instance_valid(node):
                continue
            node.set_instance_shader_parameter(property, value)


func GetEffectFlags() -> int:
    if _shaderNodes.size() > 0 and is_instance_valid(_shaderNodes[0]):
        var value = _shaderNodes[0].get_instance_shader_parameter("effectFlags")
        return value if value != null else 0
    return 0


func SetEffectFlags(flags: int) -> void :
    for node: AdobeAnimateSpriteBase in _shaderNodes:
        if !is_instance_valid(node):
            continue
        node.set_instance_shader_parameter("effectFlags", flags)





func SetChildShaderParameter(parentNode: Node2D, property: String, value: Variant) -> void :
    if !is_instance_valid(parentNode):
        return
    if SHADER_EFFECT_FLAGS.has(property):
        var flag: int = SHADER_EFFECT_FLAGS[property]
        if parentNode is AdobeAnimateSpriteBase:
            var current: int = parentNode.get_instance_shader_parameter("effectFlags") if parentNode.get_instance_shader_parameter("effectFlags") != null else 0
            if value:
                current |= flag
            else:
                current &= ~ flag
            parentNode.set_instance_shader_parameter("effectFlags", current)
        for child in parentNode.get_children():
            SetChildShaderParameter(child, property, value)
        return
    if parentNode is AdobeAnimateSpriteBase:
        parentNode.set_instance_shader_parameter(property, value)
    for child in parentNode.get_children():
        SetChildShaderParameter(child, property, value)
