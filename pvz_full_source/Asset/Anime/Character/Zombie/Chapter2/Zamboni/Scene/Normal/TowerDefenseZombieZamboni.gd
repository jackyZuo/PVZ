@tool
extends TowerDefenseZombie

const ZAMBONI_EXPLOSION = preload("uid://bbsti03vlotx6")

@onready var zamboniSmoke: GPUParticles2D = %ZamboniSmoke
@onready var iceCapMarker: Marker2D = %IceCapMarker

var speed: float = 30.0
var audioPlay: bool = false

@warning_ignore("unused_parameter")
func WalkProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 0.5
    if !sprite.pause:
        if global_position.x > TowerDefenseManager.GetMapGroundRight():
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * 2.0 * (-1 if sprite.playBack else 1)
        else:
            global_position.x -= speed * delta * sprite.timeScale * transformPoint.scale.x * scale.x * (-1 if sprite.playBack else 1)
    if !audioPlay:
        if global_position.x < TowerDefenseManager.GetMapGroundRight():
            AudioManager.AudioPlay("Zamboni", AudioManagerEnum.TYPE.SFX)
            audioPlay = true
    if !instance.hypnoses:
        TowerDefenseManager.SetIceCapPos(gridPos.y, iceCapMarker.global_position)

    if attackComponent.CanAttack():
        if attackComponent.target is TowerDefensePlant:
            if is_instance_valid(attackComponent.target.cell):
                if attackComponent.target.cell.HasSpike():
                    attackComponent.target = attackComponent.target.cell.GetSpike()

        if !attackComponent.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
            attackComponent.SmashAttackCell(config.smashAttack)
        else:
            if attackComponent.target.instance.spikeHurt != -1:
                attackComponent.target.Hurt(attackComponent.target.instance.spikeHurt)
            Die()

    if instance.hitpoints < (config.hitpoints + config.hitpointsNearDeath) * 0.2:
        if speed > 5:
            speed -= delta * 1.0
        sprite.shake = true

func HitpointsEmpty() -> void :
    super.HitpointsEmpty()
    if !isExplode:
        CreateEffect()
        Destroy()
    else:
        spritePause = true

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "DamagePoint2":
            speed = speed / 1.2
        "DamagePoint3":
            speed = speed / 1.5
            zamboniSmoke.visible = true

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Wheelie":
            CreateEffect()
        "Wheelie2":
            CreateEffect()

func CreateEffect() -> void :
    AudioManager.AudioPlay("ZamboniExplosion", AudioManagerEnum.TYPE.SFX)
    ViewManager.CameraShake(Vector2(randf_range(-1, 1), randf_range(-1, 1)), 5.0, 0.05, 4)
    var effect: TowerDefenseEffectParticlesOnce = TowerDefenseManager.CreateEffectParticlesOnce(ZAMBONI_EXPLOSION, gridPos)
    effect.global_position = global_position
    characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {
        "speed": speed, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    speed = data.get("speed", 30.0)
