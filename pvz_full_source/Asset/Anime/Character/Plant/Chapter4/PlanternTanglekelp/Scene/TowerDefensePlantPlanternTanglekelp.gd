@tool
extends TowerDefensePlant

@onready var tanglekelpComponent: TanglekelpComponent = %TanglekelpComponent

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var attackComponent2: AttackComponent = %AttackComponent2
@onready var attackShape: CollisionShape2D = %AttackShape
@onready var checkShape: CollisionShape2D = %CheckShape
@onready var checkArea: Area2D = %CheckArea

@export var eventList: Array[TowerDefenseCharacterEventBase] = []
@export var attackInterval: float = 0.5

var over: bool = false

var attackTimer: float = 0.0

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    attackShape.shape = attackShape.shape.duplicate(true)
    attackShape.shape.size = TowerDefenseManager.GetMapGridSize() * 2.75

    checkShape.shape = checkShape.shape.duplicate(true)
    checkShape.shape.size.x = TowerDefenseManager.GetMapGridSize().x * 2.75
    if currentCustom.has("Custom0"):
        tanglekelpComponent.grabFliterOpen = ["skin7", "skin8"]
        tanglekelpComponent.grabFliterClose = ["Layer 29", "Layer 32"]

func OnCustomSwitched(customKey: String) -> void :
    if customKey == "Custom0":
        tanglekelpComponent.grabFliterOpen = ["skin7", "skin8"]
        tanglekelpComponent.grabFliterClose = ["Layer 29", "Layer 32"]
    else:
        tanglekelpComponent.grabFliterOpen = []
        tanglekelpComponent.grabFliterClose = []

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if attackTimer >= attackInterval:
        if attackComponent2.CanAttack():
            TowerDefenseExplode.CreateExplode(global_position, Vector2(1.3, 1.3), eventList, [], camp, instance.collisionFlags)
            attackTimer = 0.0
    else:
        attackTimer += delta

func DestroySet() -> void :
    if over:
        return
    over = true
    instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE + TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.UNDER_WATER
    var targetList = attackComponent.GetTargetList()
    if targetList.size() > 0:
        if inWater:
            for target in targetList:
                if !is_instance_valid(target) || !CanCollision(target.instance.maskFlags):
                    continue
                tanglekelpComponent.Drag(target)
        else:
            for target in targetList:
                if !is_instance_valid(target) || !CanCollision(target.instance.maskFlags):
                    continue
                HitBack(target)

        await get_tree().create_timer(0.6, false).timeout


func HitBack(character: TowerDefenseCharacter) -> void :
    if character is TowerDefenseZombie:
        character.ySpeed = -200
        var tween = character.create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(character, ^"global_position:x", (TowerDefenseManager.GetMapGroundLeft() + 60) if instance.hypnoses else (character.groundRight - 60), 2.0)
    var dizzinessBuff: TowerDefenseCharacterBuffDizziness = TowerDefenseCharacterBuffDizziness.new()
    dizzinessBuff.time = 3.0
    character.BuffAdd(dizzinessBuff)

func ExportVariantSave() -> Dictionary:
    return {
        "attackInterval": attackInterval, 
        "over": over, 
        "attackTimer": attackTimer, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    attackInterval = data.get("attackInterval", 0.5)
    over = data.get("over", false)
    attackTimer = data.get("attackTimer", 0.0)
