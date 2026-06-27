@tool
extends TowerDefensePlant

const SUANIAO_SCENE: PackedScene = preload("uid://d108rh2c5elsf")

var _over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.invincibleHurt = true

func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if !is_instance_valid(character):
        return
    match type:
        "Eat":
            SkipInvincibleHurt(max(10.0, num))
            ApplySuanNiao(character)
        "Smash":
            SkipInvincibleHurt(num)
        "Chomp":
            Destroy()

func ApplySuanNiao(character: TowerDefenseCharacter) -> void :
    if !character is TowerDefenseZombie: return
    var zombie: TowerDefenseZombie = character
    if zombie.nearDie or zombie.die or zombie.isGarlicBird or zombie.isChangeLine: return
    zombie.isGarlicBird = true
    zombie.attackComponent.alive = false
    zombie.Walk()
    var effect: = SUANIAO_SCENE.instantiate()
    effect.position = Vector2(0, -100)
    zombie.add_child(effect)
    var timer: = Timer.new()
    timer.one_shot = true
    timer.wait_time = 5.0
    zombie.add_child(timer)
    timer.timeout.connect( func():
        if is_instance_valid(effect): effect.queue_free()
        if is_instance_valid(zombie) and !zombie.nearDie and !zombie.die:
            zombie.attackComponent.alive = true
            zombie.ChangeLine()
        if is_instance_valid(zombie): zombie.isGarlicBird = false
        if is_instance_valid(timer): timer.queue_free()
    )
    timer.start()

func DestroySet() -> void :
    if _over:
        return
    _over = true
    super.DestroySet()
    sprite.SetAnimation("Fire", false, 0.2)
    instance.invincible = true
    var target_x: float = TowerDefenseManager.GetMapGroundRight() + 200
    var charge_distance: float = target_x - global_position.x
    var duration: float = maxf(2.0, charge_distance / 200.0)
    var charge_tween: = create_tween()
    charge_tween.tween_property(self, ^"global_position:x", target_x, duration)
    var hit_zombies: Array = []
    while charge_tween.is_valid() and charge_tween.is_running():
        var zombie_list: Array = TowerDefenseManager.GetCharacterLine(gridPos.y, false)
        for character in zombie_list:
            if !is_instance_valid(character):
                continue
            if character.camp == camp:
                continue
            if character.nearDie or character.die:
                continue
            if !is_instance_valid(character.hitBox) or !character.hitBox.monitorable:
                continue
            if character in hit_zombies:
                continue
            if abs(character.global_position.x - global_position.x) < 100:
                character.SkipInvincibleHurt(1000.0)
                ApplySuanNiao(character)
                hit_zombies.append(character)
        await get_tree().physics_frame
    Destroy()
