@tool
extends TowerDefensePlant

@onready var collisionShape: CollisionShape2D = %CollisionShape

var over: bool = false

var springList: Array

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    collisionShape.shape.size = TowerDefenseManager.GetMapGridSize() * 0.5

func CanSleep() -> bool:
    if TowerDefenseManager.IsIZMMode():
        return false
    return super.CanSleep()

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    instance.canBeCollection = true
    if is_instance_valid(hitBox):
        if hitBox.has_overlapping_areas():
            for area in hitBox.get_overlapping_areas():
                HitboxEntered(area)

func HitboxEntered(area: Area2D) -> void :
    if instance.sleep:
        return
    var character = area.get_parent()
    if springList.has(character):
        return
    if character is TowerDefenseCharacter:
        if character.die || character.nearDie:
            return
        if character.instance.invincible:
            return
        if !CheckDifferentCamp(character.camp):
            return
        if !CanCollision(character.instance.maskFlags):
            return
        if !CheckSameLine(character.gridPos.y) && !character.targetRegistrationComponent.allLineCheck:
            return
        Hit(character)
        springList.append(character)
        await get_tree().create_timer(0.5).timeout
        springList.erase(character)

func Hit(character: TowerDefenseCharacter) -> void :
    if !TowerDefenseManager.IsGameRunning():
        return
    if character is TowerDefenseZombie:
        if !CanCollision(character.instance.maskFlags):
            return
        if !CanTarget(character):
            return
        if character.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.BLOW:
            return
        sprite.SetAnimation("Attack", false, 0.2)
        sprite.AddAnimation("Idle", 0.0, true)
        if character.config.physique < TowerDefenseEnum.ZOMBIE_PHYSIQUE.HUGE:
            Hurt(50.0)
        else:
            Hurt(100.0)
        character.ySpeed = -200
        var tween = character.create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        var positionX: float = character.global_position.x + TowerDefenseManager.GetMapGridSize().x * 2
        if instance.hypnoses:
            positionX = character.global_position.x - TowerDefenseManager.GetMapGridSize().x * 2
        tween.tween_property(character, ^"global_position:x", positionX, 2.0)
        if character.get("jumpOver") != null:
            character.jumpOver = true
            if character.get("moveTween") != null:
                var mt: Tween = character.get("moveTween")
                if is_instance_valid(mt) && mt.is_running():
                    mt.kill()
            character.Walk()

func Flip() -> void :
    if !instance.sleep:
        sprite.SetAnimation("Attack", false, 0.2)
    else:
        sprite.SetAnimation("Attack", false, 0.2)
        sprite.AddAnimation("Sleep", 0.0, true)

func BlockCharacter() -> void :
    sprite.SetAnimation("Attack", false, 0.2)
    sprite.AddAnimation("Idle", 0.0, true)
    Hurt(50.0)

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
