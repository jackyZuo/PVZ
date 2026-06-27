@tool
extends TowerDefenseItem

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var collisionShape: CollisionShape2D = %CollisionShape

@export var attack: float = 20.0

@export var fireInterval: float = 1.5:
    set(_fireInterval):
        fireInterval = _fireInterval
        if !is_node_ready():
            await ready
        attackComponent.attackInterval = fireInterval

var carryCharacter: TowerDefenseZombie

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size.x = TowerDefenseManager.GetMapGridSize().x * 1.2

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if is_instance_valid(targetZombie):
        if !Carry(targetZombie):
            Destroy()
            return
    if is_instance_valid(carryCharacter):
        if carryCharacter.nearDie || carryCharacter.die:
            Destroy()
            return
        groundHeight = carryCharacter.groundHeight
        z = 10
        global_position = carryCharacter.global_position
        gridPos = carryCharacter.gridPos

func ComponentAttack() -> void :
    AudioManager.AudioPlay("ProjectileThrow", AudioManagerEnum.TYPE.SFX)
    attackComponent.AttackAllFlag(attack, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY)

func Carry(character: TowerDefenseZombie) -> TowerDefenseCharacter:
    targetZombie = null
    if character is TowerDefenseZombie:
        if character.isRise:
            return
        if character.hasSpikeball:
            return
        if character.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE == 0:
            return
        if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
            return
        if character.camp != camp:
            return
        if !character.targetRegistrationComponent.canCarry:
            return
    @warning_ignore("confusable_local_declaration", "unused_parameter")
    character.destroy.connect( func(character: TowerDefenseCharacter):
        Destroy()
    )
    carryCharacter = character
    carryCharacter.hasSpikeball = true
    groundHeight = carryCharacter.groundHeight
    z = 10
    attackComponent.checkArea = carryCharacter.hitBox
    attackComponent.checkArea.connect("area_entered", func(area: Area2D):
        var enterCharacter = area.get_parent()
        if enterCharacter is TowerDefenseZombie && !enterCharacter.nearDie && !enterCharacter.die && enterCharacter.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.CAR:
            enterCharacter.Die()
            Destroy()
    )
    return carryCharacter

func ExportVariantSave() -> Dictionary:
    return {"attack": attack, 
        "fireInterval": fireInterval, }

func ImportVariantSave(data: Dictionary) -> void :
    attack = data.get("attack", 20.0)
    fireInterval = data.get("fireInterval", 1.0)
