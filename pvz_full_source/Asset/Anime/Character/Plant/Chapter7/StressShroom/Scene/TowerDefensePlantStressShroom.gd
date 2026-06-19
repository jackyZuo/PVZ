@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var checkShape2: CollisionShape2D = %CheckShape2
@onready var fireParticles: GPUParticles2D = %FireParticles
@onready var fireParticles2: GPUParticles2D = %FireParticles2
@onready var fireParticles3: GPUParticles2D = %FireParticles3
@onready var fireParticles4: GPUParticles2D = %FireParticles4

@export var fireInterval: float = 2.0:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

@export var level: int = 1

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    checkShape.shape.b.x = TowerDefenseManager.GetMapGridSize().x * 6.5
    checkShape2.shape.b.x = TowerDefenseManager.GetMapGridSize().y * 6.5

    fireParticles.process_material = fireParticles.process_material.duplicate_deep()
    fireParticles2.process_material = fireParticles.process_material
    fireParticles3.process_material = fireParticles.process_material
    fireParticles4.process_material = fireParticles.process_material

func Attack() -> void :
    fireParticles.restart()
    fireParticles2.restart()
    fireParticles3.restart()
    fireParticles4.restart()
    AudioManager.AudioPlay("Fume", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackEventExecute()

func Cover(character: TowerDefenseCharacter) -> void :
    if character.config.name == "PlantStressShroom":
        level = clampi(character.level + 1, 1, 4)
        LevelSet(level)
        if character.instance.wakeUp:
            instance.wakeUp = true

func LevelSet(lv: int) -> void :
    match lv:
        2:
            sprite.SetFliters(["Upgrade1_eyebrow", "Upgrade1_helmet", "Upgrade2_barrel"], true)
            instance.hitpoints += 300
            instance.hitpointsSave += 300
            attackComponent.eventList[0].num += 20
            attackComponent.attackEventName = "fire"
            attackComponent.attackAnimeClips = "Fire2"
            fireParticles.scale *= 1.25
            fireParticles.process_material.scale_max *= 1.25
            fireParticles.process_material.scale_min *= 1.25
            idleAnimeClip = "Idle2"
            sleepAnimeClip = "Sleep2"
        3:
            sprite.SetFliters(["Upgrade1_eyebrow", "Upgrade1_eyebrow2", "Upgrade1_helmet", "Upgrade2_helmet", "Upgrade2_barrel", "Upgrade2_barrel2", "Upgrade2_face"], true)
            instance.hitpoints += 600
            instance.hitpointsSave += 600
            attackComponent.eventList[0].num += 40
            attackComponent.attackEventName = "fire"
            attackComponent.attackAnimeClips = "Fire3"
            fireParticles.process_material.scale_max *= 1.5
            fireParticles.process_material.scale_min *= 1.5
            idleAnimeClip = "Idle3"
            sleepAnimeClip = "Sleep3"
        4:
            sprite.SetFliters(["Upgrade1_eyebrow", "Upgrade1_eyebrow2", "Upgrade1_helmet", "Upgrade2_helmet", "Upgrade2_barrel", "Upgrade2_barrel2", "Upgrade2_face"], true)
            instance.hitpoints += 900
            instance.hitpointsSave += 900
            attackComponent.eventList[0].num += 60
            attackComponent.attackEventName = "fire"
            attackComponent.attackAnimeClips = "Fire4"
            fireParticles.process_material.scale_max *= 1.75
            fireParticles.process_material.scale_min *= 1.75
            idleAnimeClip = "Idle4"
            sleepAnimeClip = "Sleep4"

func ExportVariantSave() -> Dictionary:
    return {"level": level, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    level = data.get("level", 1)
    if level > 1:
        LevelSet(level)
    fireInterval = data.get("fireInterval", 2.0)
