@tool
extends TowerDefenseZombie
const ZOMBIE_SNAIL_SHELL = preload("uid://bhwtjd6lkwqhh")

var hasShell: bool = true:
    set(_hasShell):
        hasShell = _hasShell
        if hasShell:
            dieAnimeClip = "Death2"
            dieWaterAnimeClip = "Death2"
        else:
            dieAnimeClip = "Death"
            dieWaterAnimeClip = "Death"

var over: bool = false

func HitpointsNearDie() -> void :
    if !die:
        Die()

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    instance.keepArmor = true

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if die || nearDie:
        return
    if is_instance_valid(cell):
        if cell.IsWater():
            Die()

func DieEntered() -> void :
    if !die:
        HitpointsEmpty()
        die = true
    if !nearDie:
        HitpointsNearDie()
        nearDie = true
    if camp == TowerDefenseEnum.CHARACTER_CAMP.ZOMBIE:
        if GameSaveManager.GetFeatureValue("Coins"):
            var item = TowerDefenseManager.FallingObjectCreate(global_position, GetGroundHeight(global_position.y), Vector2(randf_range(-50.0, 50.0), -400.0), 980.0)
            if item:
                item.gridPos = gridPos
    sprite.SetAnimation(dieAnimeClip, false)

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Shell":
            hasShell = false
            var effect = TowerDefenseManager.CreateEffectSpriteOnce(ZOMBIE_SNAIL_SHELL, gridPos, "Death")
            effect.global_position = global_position
            characterNode.add_child(effect)

func ExportVariantSave() -> Dictionary:
    return {
        "hasShell": hasShell, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    hasShell = data.get("hasShell", true)
    over = data.get("over", false)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    if dieAnimeClip.split("&", false).has(clip):
        if over:
            return
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            over = true
            await get_tree().physics_frame
            Destroy()
            return
        over = true
        if !hasShell:
            return
        var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig("ZombieSnailShell")
        var shell = packetConfig.Create(global_position, gridPos, 0)
        characterNode.add_child(shell)
        if instance.hypnoses:
            shell.Hypnoses.call_deferred()
        var _hitpointScale: float = instance.hitpointScale
        var _scale: Vector2 = transformPoint.scale
        ( func():
            if is_instance_valid(shell):
                if is_instance_valid(shell.instance):
                    shell.instance.hitpointScale = _hitpointScale
                if is_instance_valid(shell.transformPoint):
                    shell.transformPoint.scale = _scale).call_deferred()
        shell.set_deferred("invisible", invisible)
        var shellArmor = shell.GetArmorFromName("Shell")
        var armor = GetArmorFromName("Shell")
        shellArmor.Hurt(armor.config.damagePoint - armor.hitPoints)
        if instance.hypnoses:
            shell.Hypnoses()
        shell.Walk.call_deferred()
        await get_tree().physics_frame
        Destroy()
        return
