@tool
extends TowerDefenseItem

@onready var moveComponent: MoveComponent = %MoveComponent
@onready var bowlingComponent: BowlingComponent = %BowlingComponent
@onready var mousePressComponent: MousePressComponent = %MousePressComponent

var hitNum: int = 0:
    set(_hitNum):
        hitNum = _hitNum
        HitNumCheck()

var hitFinish: bool = false

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    shadowComponent.saveShadowPosition.y = global_position.y + 30
    super._physics_process(delta)
    gridPos = TowerDefenseManager.GetMapGridPos(global_position)

func IdleEntered() -> void :
    sprite.SetAnimation("Rise", false, 0.0)
    sprite.AddAnimation("Idle", 0.0, true, 0.0)

@warning_ignore("unused_parameter")
func ExplodeHurt(num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    if sprite.clip == "Roll":
        if type == "Jala":
            Destroy()
    return 0

func SetSize(size: String) -> void :
    match size:
        "Small":
            var hurtEvent = bowlingComponent.hitEvent[0].duplicate(true)
            hurtEvent.num = 100
            bowlingComponent.hitEvent[0] = hurtEvent
            transformPoint.scale = 0.5 * Vector2.ONE
            shadowComponent.saveShadowScale = 1.0 * Vector2.ONE
            shadowComponent.saveTransformPointScale = transformPoint.scale
        "Normal":
            var hurtEvent = bowlingComponent.hitEvent[0].duplicate(true)
            hurtEvent.num = 200
            bowlingComponent.hitEvent[0] = hurtEvent
            transformPoint.scale = 0.8 * Vector2.ONE
            shadowComponent.saveShadowScale = 1.6 * Vector2.ONE
            shadowComponent.saveTransformPointScale = transformPoint.scale
        "Large":
            var hurtEvent = bowlingComponent.hitEvent[0].duplicate(true)
            hurtEvent.num = 400
            bowlingComponent.hitEvent[0] = hurtEvent
            transformPoint.scale = 1.25 * Vector2.ONE
            shadowComponent.saveShadowScale = 2.5 * Vector2.ONE
            shadowComponent.saveTransformPointScale = transformPoint.scale
        "Max":
            bowlingComponent.rollXVelocityMax = 150
            bowlingComponent.rollXVelocityMin = 100
            bowlingComponent.edgeReboundUse = false
            bowlingComponent.hitLineUse = true
            bowlingComponent.hitLineBackUse = false
            bowlingComponent.alive = true
            mousePressComponent.alive = false
            hitFinish = true
            var hurtEvent = bowlingComponent.hitEvent[0].duplicate(true)
            hurtEvent.num = 400
            bowlingComponent.hitEvent[0] = hurtEvent
            transformPoint.scale = 1.5 * Vector2.ONE
            shadowComponent.saveShadowScale = 3.0 * Vector2.ONE
            shadowComponent.saveTransformPointScale = transformPoint.scale

@warning_ignore("unused_parameter")
func Pressed(pos: Vector2) -> void :
    bowlingComponent.alive = true
    mousePressComponent.alive = false

@warning_ignore("unused_parameter")
func Bowling(character: TowerDefenseCharacter) -> void :
    hitNum += 1

func EdgeRebound() -> void :
    hitNum += 1

func HitNumCheck() -> void :
    if hitFinish:
        return
    if is_instance_valid(moveComponent):
        if moveComponent.velocity.x < 0:
            return
        if hitNum >= 5:
            bowlingComponent.edgeReboundUse = false
            bowlingComponent.hitLineUse = false
            hitFinish = true

func InWater() -> void :
    super.InWater()
    if abs(transformPoint.scale.x) >= 0.75:
        return
    CreateSplash()
    Destroy()

func AreaEntered(area: Area2D) -> void :
    var character = area.get_parent()
    if character is TowerDefenseCharacter:
        if character.config.name == "ItemSnowBall":
            if character.bowlingComponent.alive:
                return
            character.Pressed(character.global_position)

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    if instance.hypnoses:
        moveComponent.moveScale = -1.0
        bowlingComponent.alive = true
        mousePressComponent.alive = false
    else:
        moveComponent.moveScale = 1.0
