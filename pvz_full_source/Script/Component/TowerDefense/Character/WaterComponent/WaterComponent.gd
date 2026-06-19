
class_name WaterComponent extends ComponentBase


@export var waterLineSprite: AdobeAnimateSpriteBase

@export var waterHeight: float = 35

@export var waterIdleAnime: String


var saveIdleAnime: String


var parent: TowerDefenseCharacter


var inWater: bool = false:
    set = SetInWater


var _gridSize: Vector2


func GetName() -> String:
    return "WaterComponent"


func _ready() -> void :
    parent = get_parent().parent as TowerDefenseCharacter
    _gridSize = TowerDefenseManager.GetMapGridSize()
    saveIdleAnime = parent.idleAnimeClip
    if !parent.is_node_ready():
        await parent.ready
    UpdateIsInWater()


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void :
    if !alive:
        return
    UpdateIsInWater()

    if inWater:
        parent.groundHeight = lerpf(parent.groundHeight, - waterHeight, delta * 3.0)
    else:
        if is_instance_valid(parent.cell):
            if parent is TowerDefenseZombie:
                var cellPos: Vector2 = TowerDefenseManager.GetMapCellPos(parent.gridPos)
                var offset: Vector2 = parent.global_position - parent.cellPos
                parent.cellPercentage = offset.x / _gridSize.x
            parent.groundHeight = lerpf(parent.groundHeight, parent.cell.GetGroundHeight(parent.cellPercentage), delta * 3.0)
        else:
            parent.groundHeight = lerpf(parent.groundHeight, 0.0, delta * 3.0)


func UpdateIsInWater() -> void :
    if is_instance_valid(parent.cell) && parent.cell.IsWater():
        if is_instance_valid(parent.cell.slot[TowerDefenseEnum.PLANTGRIDTYPE.WATER]) && parent.cell.slot[TowerDefenseEnum.PLANTGRIDTYPE.WATER] != parent:
            inWater = false
        else:
            inWater = true
    else:
        inWater = false



func SetInWater(_inWater: bool) -> void :
    if inWater != _inWater:
        inWater = _inWater
        parent.inWater = inWater
        if parent.inGame:
            if inWater:
                InWater()
                parent.InWater()
            else:
                OutWater()
                parent.OutWater()


func InWater() -> void :
    if waterIdleAnime != "":
        parent.idleAnimeClip = waterIdleAnime
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    parent.SetSpriteGroupShaderParameter("discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 45))).y)
    var _spriteMaterial: ShaderMaterial = parent.sprite.material as ShaderMaterial
    if is_instance_valid(_spriteMaterial) && _spriteMaterial.get_shader_parameter("discardDownPos") != null:
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(_spriteMaterial, "shader_parameter/discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 45))).y, 1.0)

    parent.CreateSplash()

    if is_instance_valid(waterLineSprite):
        waterLineSprite.visible = true


func OutWater() -> void :
    if parent.idleAnimeClip != saveIdleAnime:
        parent.idleAnimeClip = saveIdleAnime
        parent.Idle()
    var viewport: Viewport = get_viewport()
    var vt: Transform2D = viewport.get_screen_transform()
    vt.origin = Vector2.ZERO
    parent.SetSpriteGroupShaderParameter("discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 56))).y)
    var _spriteMaterial: ShaderMaterial = parent.sprite.material as ShaderMaterial
    var tween: Tween = null
    if is_instance_valid(_spriteMaterial) && _spriteMaterial.get_shader_parameter("discardDownPos") != null:
        tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(_spriteMaterial, "shader_parameter/discardDownPos", (vt * (parent.spriteGroup.global_position + Vector2(0, 86))).y, 1.0)

    if is_instance_valid(waterLineSprite):
        waterLineSprite.visible = false

    if is_instance_valid(tween):
        await tween.finished
    parent.SetSpriteGroupShaderParameter("discardDownPos", 10000.0)
