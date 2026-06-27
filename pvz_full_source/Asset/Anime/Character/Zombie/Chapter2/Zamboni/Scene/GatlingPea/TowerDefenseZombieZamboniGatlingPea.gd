@tool
extends TowerDefenseZombie

const ZAMBONI_EXPLOSION = preload("uid://bbsti03vlotx6")

@onready var zamboniSmoke: GPUParticles2D = %ZamboniSmoke
@onready var iceCapMarker: Marker2D = %IceCapMarker

@onready var fireComponent: FireComponent = %FireComponent

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        fireComponent.fireInterval = fireInterval

@export var fireNum: int = 1:
    set(_fireNum):
        fireNum = _fireNum
        if !is_node_ready():
            await ready
        fireComponent.fireNum = fireNum

@export var projectileName: String = "Pea":
    set(_projectileName):
        projectileName = _projectileName
        if !is_node_ready():
            await ready
        fireComponent.fireCheckList[0].projectile.projectileName = projectileName

var speed: float = 30.0
var audioPlay: bool = false

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    fireComponent.fireInterval = fireInterval

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
            speed = 25.0
        "DamagePoint3":
            speed = 20.0
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

func Purify() -> void :
    if !is_instance_valid(cell):
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("PlantGatlingPea")
    if cell.CanPacketPlant(packetConfig, true):
        var character: TowerDefenseCharacter = packetConfig.Plant(gridPos, true, true)
        character.WakeUp()
        if instance.hypnoses:
            character.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt("PlantGatlingPea", gridPos.x, gridPos.y, _sync_id)
    Destroy()
