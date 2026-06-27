@tool
extends TowerDefensePlant

@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

var crater: TowerDefenseCharacter

func _ready() -> void :
    zombiePlaceDamage = 3000.0
    super._ready()
    if Engine.is_editor_hint():
        return
    await get_tree().physics_frame
    if is_instance_valid(targetZombie):
        explodeComponent.explodeAnimeTimeScale = 2.0
        explodeComponent.explodeAnimeClips = "WhackZombie"
        return
    if is_instance_valid(cell):
        crater = cell.FindSlotParent(self)

func Explode() -> void :
    if is_instance_valid(targetZombie):
        AudioManager.AudioPlay("Bonk", AudioManagerEnum.TYPE.SFX)
        explodeComponent.CreateParticlesEffect()
        targetZombie.Hurt(zombiePlaceDamage, true, Vector2.ZERO, false)
        targetZombie.AttackDeal(null, "Explode", zombiePlaceDamage)
        return
    if is_instance_valid(crater):
        crater.Destroy()
        var goldShardCreateEvent: TowerDefenseCharacterEventGoldShardCreate = TowerDefenseCharacterEventGoldShardCreate.new()
        goldShardCreateEvent.num = 1
        goldShardCreateEvent.Execute(global_position, self)
