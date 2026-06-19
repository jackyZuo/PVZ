
class_name WaterInteractionComponent extends ComponentBase


@export var waterLineSprite: AdobeAnimateSpriteBase

@export var duckytobeSprite: AdobeAnimateSpriteBase

@export var inWaterLine: bool = false

@export var handleDuckytobe: bool = false

@export var discardOffsetIn: float = 36.0

@export var discardOffsetOut: float = 56.0

@export var discardOffsetOutTarget: float = 86.0


var parent: TowerDefenseCharacter

var outFromWater: bool = false

var isInWater: bool = false

var activeTween: Tween = null

var _lastScaleRatioY: float = 1.0

var shadowComponent: ShadowComponent

var saveTransformPointScaleY: float = 1.0

var saveSpriteGroupScaleY: float = 1.0


signal waterEnter()

signal waterExit()


func GetName() -> String:
    return "WaterInteractionComponent"


func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready
    saveTransformPointScaleY = parent.transformPoint.scale.y
    saveSpriteGroupScaleY = parent.spriteGroup.scale.y
    BattleEventBus.screenTransformChanged.connect(_on_screen_transform_changed)

func _on_screen_transform_changed() -> void :
    if isInWater:
        if is_instance_valid(activeTween):
            activeTween.kill()
        InWaterDiscardSet()

func _process(_delta: float) -> void :
    if !isInWater:
        return
    var currentScaleRatioY: float = GetScaleRatioY()
    if !is_equal_approx(currentScaleRatioY, _lastScaleRatioY):
        _lastScaleRatioY = currentScaleRatioY
        if is_instance_valid(activeTween):
            activeTween.kill()
        InWaterDiscardSet()

func GetScaleRatioY() -> float:
    return (abs(parent.spriteGroup.scale.y) * abs(parent.transformPoint.scale.y)) / max(abs(saveSpriteGroupScaleY) * abs(saveTransformPointScaleY), 0.001)


func InWater() -> void :
    isInWater = true
    _lastScaleRatioY = GetScaleRatioY()
    if is_instance_valid(shadowComponent):
        shadowComponent.SetVisible(false)
    else:
        parent.shadowSprite.visible = false
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    var scaledOffsetIn: float = discardOffsetIn * GetScaleRatioY() + parent.groundHeight
    var targetPosIn: float = (vt * (parent.spriteGroup.global_position + Vector2(0, scaledOffsetIn))).y
    parent.SetSpriteGroupShaderParameter("discardDownPos", targetPosIn)
    var _spriteMaterial: ShaderMaterial = parent.sprite.material as ShaderMaterial
    if is_instance_valid(_spriteMaterial) && _spriteMaterial.get_shader_parameter("discardDownPos") != null:
        activeTween = create_tween()
        activeTween.set_ease(Tween.EASE_OUT)
        activeTween.set_trans(Tween.TRANS_CUBIC)
        activeTween.tween_property(_spriteMaterial, "shader_parameter/discardDownPos", targetPosIn, 1.0)
    parent.CreateSplash()
    if is_instance_valid(waterLineSprite):
        waterLineSprite.visible = true
    if handleDuckytobe && is_instance_valid(duckytobeSprite):
        if !duckytobeSprite.visible:
            duckytobeSprite.visible = true
        if inWaterLine:
            duckytobeSprite.SetFliters(["Zombie_duckytube_inwater"], true)
            duckytobeSprite.SetFliters(["Zombie_duckytube"], false)
        else:
            duckytobeSprite.SetFliters(["Zombie_duckytube_inwater", "Zombie_duckytube"], false)
    waterEnter.emit()


func OutWater() -> void :
    isInWater = false
    outFromWater = true
    if is_instance_valid(shadowComponent):
        shadowComponent.SetVisible( !parent.invisible)
    else:
        parent.shadowSprite.visible = !parent.invisible
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    var scaleRatio: float = GetScaleRatioY()
    var scaledOffsetOut: float = discardOffsetOut * scaleRatio + parent.groundHeight
    var scaledOffsetOutTarget: float = discardOffsetOutTarget * scaleRatio + parent.groundHeight
    var targetPosOut: float = (vt * (parent.spriteGroup.global_position + Vector2(0, scaledOffsetOut))).y
    var targetPosOutFinal: float = (vt * (parent.spriteGroup.global_position + Vector2(0, scaledOffsetOutTarget))).y
    parent.SetSpriteGroupShaderParameter("discardDownPos", targetPosOut)
    var _spriteMaterial: ShaderMaterial = parent.sprite.material as ShaderMaterial
    if is_instance_valid(_spriteMaterial) && _spriteMaterial.get_shader_parameter("discardDownPos") != null:
        activeTween = create_tween()
        activeTween.set_parallel(true)
        activeTween.set_ease(Tween.EASE_OUT)
        activeTween.set_trans(Tween.TRANS_CUBIC)
        activeTween.tween_property(_spriteMaterial, "shader_parameter/discardDownPos", targetPosOutFinal, 1.0)
    if is_instance_valid(waterLineSprite):
        waterLineSprite.visible = false
    if handleDuckytobe && is_instance_valid(duckytobeSprite):
        if inWaterLine:
            duckytobeSprite.SetFliters(["Zombie_duckytube_inwater"], false)
            duckytobeSprite.SetFliters(["Zombie_duckytube"], true)
        else:
            duckytobeSprite.SetFliters(["Zombie_duckytube_inwater", "Zombie_duckytube"], false)
    if is_instance_valid(activeTween):
        await activeTween.finished
    parent.SetSpriteGroupShaderParameter("discardDownPos", 10000.0)
    waterExit.emit()


func InWaterDiscardSet() -> void :
    isInWater = true
    _lastScaleRatioY = GetScaleRatioY()
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    var scaledOffsetIn: float = discardOffsetIn * GetScaleRatioY() + parent.groundHeight
    parent.SetSpriteGroupShaderParameter("discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, scaledOffsetIn))).y)


func OutWaterDiscardSet() -> void :
    isInWater = false
    parent.SetSpriteGroupShaderParameter("discardDownPos", 10000.0)
