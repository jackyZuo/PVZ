@tool
extends TowerDefensePlant

@onready var squashComponent: SquashComponent = %SquashComponent

@onready var attackComponent: AttackComponent = %AttackComponent

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return

    instance.invincible = true
    z = 600.0
    isGround = false

    sprite.SetAnimation("JumpUp", false, 0.0)

    land.connect(OnLanded)


func OnLanded() -> void :

    if is_instance_valid(self):
        land.disconnect(OnLanded)
    sprite.SetAnimation("JumpDown", false, 0.0)

    SummonBungi()

    await get_tree().create_timer(0.5, false).timeout
    if is_instance_valid(self):
        Destroy()


func SummonBungi() -> void :
    var bungi = CreateCharacter("ZombieBungi", global_position, gridPos, 0.0)
    await get_tree().physics_frame
    bungi.HitBoxDestroy()
    bungi.instance.invincible = true
    bungi.skipBungeeTarget = true
    bungi.Hypnoses()
    bungi.Walk()
