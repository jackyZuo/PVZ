@tool
extends TowerDefensePlant

@export var forzenTime: float = 5.0
@onready var moveComponent: MoveComponent = %MoveComponent

var isNut: bool = false
var isCrawl: bool = false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    instance.hitpointsEmpty.disconnect(Destroy)
    instance.keepAlive = true

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if isCrawl:
        shadowComponent.saveShadowPosition.y = global_position.y + 30
        gridPos = TowerDefenseManager.GetMapGridPos(global_position)
        if (global_position.x > groundRight + 150 || global_position.x < -100):
            Destroy()

@warning_ignore("unused_parameter")
func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    sprite.timeScale = timeScale
    if instance.hitpoints <= 0:
        instance.invincible = true
        instance.hitpoints = 300
        instance.die = false
        sprite.SetAnimation("Out", false, 0.2)
        sprite.AddAnimation("Crawl", 0.0, true)
        moveComponent.SetVelocity((Vector2.LEFT if instance.hypnoses else Vector2.RIGHT) * 20.0)
        isCrawl = true
        instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
        cell.CharacterDestroy(self)

func HitBoxEntered(area: Area2D) -> void :
    if !isCrawl:
        return
    var character = area.get_parent()
    if character is TowerDefenseCharacter:
        if character.instance.die || character.instance.nearDie:
            return
        if character is TowerDefenseGravestone:
            return
        if character is TowerDefenseCrater:
            return
        if character is TowerDefensePlantBowlingBase:
            return
        if character is TowerDefenseZombie:
            if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                return
        if !CanCollision(character.instance.maskFlags):
            return
        if CheckDifferentCamp(character.camp) && (CheckSameLine(character.gridPos.y) || character.targetRegistrationComponent.allLineCheck):
            AddBuffForzen(character)
            if character is TowerDefenseZombie && character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.CAR:
                character.Die()


func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if is_instance_valid(character) && !instance.sleep:
        if !isNut:
            isNut = true
            sprite.SetAnimation("In", false, 0.2)
            sprite.AddAnimation("Nut", 0.0, true)
        AddBuffForzen(character)

func AddBuffForzen(character: TowerDefenseCharacter) -> void :
    var forzen: TowerDefenseCharacterBuffFrozen = TowerDefenseCharacterBuffFrozen.new()
    forzen.time = forzenTime
    forzen.iceSpeedDownTime = 0.0
    character.BuffAdd(forzen)

func ExportVariantSave() -> Dictionary:
    return {
        "forzenTime": forzenTime, 
        "isNut": isNut, 
        "isCrawl": isCrawl, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    forzenTime = data.get("forzenTime", 5.0)
    isNut = data.get("isNut", false)
    isCrawl = data.get("isCrawl", false)
