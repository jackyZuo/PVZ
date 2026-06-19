@tool
extends TowerDefenseGravestone

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    remove_from_group("Gravestone")
    if is_instance_valid(cell) && cell.IsWater():
        sprite.SetFliters(["Zombie_whitewater", "Zombie_whitewater_复制"], true)
        shadowSprite.visible = false
        var viewport: Viewport = get_viewport()
        var vt: Transform2D = viewport.get_screen_transform()
        vt.origin = Vector2.ZERO
        SetSpriteGroupShaderParameter("discardDownPos", (vt * (spriteGroup.global_position + Vector2(0, 24))).y)
        groundHeight = 0
    else:
        ySpeed = -200
        sprite.pause = true

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.5

func HitpointsEmpty():
    super.HitpointsEmpty()
    AudioManager.AudioPlay("BalloonPop", AudioManagerEnum.TYPE.SFX)
