
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
            var _material: ShaderMaterial = node.material as ShaderMaterial
            if is_instance_valid(_material):
                var current: int = _material.get_shader_parameter("effectFlags") if _material.get_shader_parameter("effectFlags") != null else 0
                if value:
                    current |= flag
                else:
                    current &= ~ flag
                _material.set_shader_parameter("effectFlags", current)
    else:
        for node: AdobeAnimateSpriteBase in _shaderNodes:
            if !is_instance_valid(node):
                continue
            var _material: ShaderMaterial = node.material as ShaderMaterial
            if is_instance_valid(_material):
                _material.set_shader_parameter(property, value)





func SetChildShaderParameter(parentNode: Node2D, property: String, value: Variant) -> void :
    if !is_instance_valid(parentNode):
        return
    if SHADER_EFFECT_FLAGS.has(property):
        var flag: int = SHADER_EFFECT_FLAGS[property]
        if parentNode is AdobeAnimateSpriteBase:
            var _material: ShaderMaterial = parentNode.material as ShaderMaterial
            if is_instance_valid(_material):
                var current: int = _material.get_shader_parameter("effectFlags") if _material.get_shader_parameter("effectFlags") != null else 0
                if value:
                    current |= flag
                else:
                    current &= ~ flag
                _material.set_shader_parameter("effectFlags", current)
        for child in parentNode.get_children():
            SetChildShaderParameter(child, property, value)
        return
    if parentNode is AdobeAnimateSpriteBase:
        var _material: ShaderMaterial = parentNode.material as ShaderMaterial
        if _material:
            _material.set_shader_parameter(property, value)
    for child in parentNode.get_children():
        SetChildShaderParameter(child, property, value)
