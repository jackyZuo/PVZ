@tool
extends TowerDefensePlant

var over: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.canBeCollection = false

func HitBoxEntered(area: Area2D) -> void :
    if !is_instance_valid(TowerDefenseManager.currentControl) || !TowerDefenseManager.currentControl.isGameRunning:
        return
    if !inGame:
        return
    if nearDie || die:
        return
    var character = area.get_parent()
    if character.config.name == "ZombieGhost" && character.camp != camp:
        character.Hurt(100000)

func GravebusterOver(graveStone: TowerDefenseGravestone) -> void :
    if over:
        return
    over = true
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var zombiePacket: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieGhost")
    var zombie: TowerDefenseZombie = zombiePacket.Create(global_position, gridPos, groundHeight)
    characterNode.add_child(zombie)
    await get_tree().physics_frame
    if is_instance_valid(zombie):
        zombie.Walk()
        if !instance.hypnoses:
            zombie.Hypnoses()
        zombie.instance.hitpoints = graveStone.instance.hitpoints
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        var control = TowerDefenseManager.currentControl
        if is_instance_valid(control):
            var _sync_id: int = control._get_next_sync_id()
            control._register_sync_character(_sync_id, zombie)
            MultiPlayerManager.SendSpawnCharacterAt("ZombieGhost", gridPos.x, gridPos.y, _sync_id, 1.0, 1.0, true, 0.0, true, global_position.x, global_position.y, true, groundHeight)

func ExportVariantSave() -> Dictionary:
    return {
        "over": over
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
