class_name DamagePipeline extends RefCounted

var _handlers: Array[DamageHandler] = []

func _init() -> void :
    _handlers.append(InvincibleCheckHandler.new())
    _handlers.append(DamageModifierHandler.new())
    _handlers.append(BuffModifierHandler.new())
    _handlers.append(ArmorHandler.new())
    _handlers.append(FinalApplyHandler.new())

func Process(ctx: DamageContext) -> float:
    for handler in _handlers:
        if ctx.cancelled:
            break
        handler.handle(ctx)
    return ctx.resultDamage

func ApplyHurt(character: TowerDefenseCharacter, num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, hitShield: bool = true, createDamagePart: bool = true) -> float:
    var result: float = character.instance.Hurt(num, playSplatAudio, velocity, hitShield, createDamagePart)
    BattleEventBus.characterHurt.emit(character, int(result), null)
    return result

func ApplySkipInvincibleHurt(character: TowerDefenseCharacter, num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, hitShield: bool = true, createDamagePart: bool = true) -> float:
    var result: float = character.instance.SkipInvincibleHurt(num, playSplatAudio, velocity, hitShield, createDamagePart)
    BattleEventBus.characterHurt.emit(character, int(result), null)
    return result

func ApplySmashHurt(character: TowerDefenseCharacter, num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    if character is TowerDefensePlant:
        var checkNum: float = 100000.0
        if character.instance.smashHurt != -1:
            checkNum = min(character.instance.smashHurt, checkNum)
        if is_instance_valid(character.cell):
            var slotCharacter: TowerDefenseCharacter = character.cell.GetSlot(character)
            if is_instance_valid(slotCharacter):
                if slotCharacter.instance.hitpoints - checkNum > 0 and character.instance.hitpoints - checkNum <= 0:
                    return num
    character.isSmash = true
    var result: float = character.instance.SmashHurt(num, playSplatAudio, velocity)
    character.isSmash = false
    BattleEventBus.characterHurt.emit(character, int(result), null)
    return result

func ApplyExplodeHurt(character: TowerDefenseCharacter, num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    if character is TowerDefensePlant:
        if is_instance_valid(character.cell):
            var slotCharacter: TowerDefenseCharacter = character.cell.GetSlot(character)
            if is_instance_valid(slotCharacter):
                if slotCharacter.instance.hitpoints - num > 0 and character.instance.hitpoints - num <= 0:
                    return num
    character.isExplode = true
    var result: float = character.instance.ExplodeHurt(num, type, playSplatAudio, velocity)
    character.isExplode = false
    BattleEventBus.characterHurt.emit(character, int(result), null)
    return result

func ApplyProjectileHurt(character: TowerDefenseCharacter, projectile: TowerDefenseProjectile, projectileConfig: TowerDefenseProjectileConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, isRange: bool = false, createDamagePart: bool = true) -> float:
    var result: float = character.instance.ProjectileHurt(projectile, projectileConfig, playSplatAudio, velocity, isRange, createDamagePart)
    BattleEventBus.characterHurt.emit(character, int(result), projectile)
    return result

func ApplyHurtWithAttackConfig(character: TowerDefenseCharacter, attackConfig: AttackConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    var result: float = character.instance.HurtWithAttackConfig(attackConfig, playSplatAudio, velocity, createDamagePart)
    BattleEventBus.characterHurt.emit(character, int(result), null)
    return result

func ApplyFlagHurt(character: TowerDefenseCharacter, num: float, damageFlags: int, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true, isRange: bool = false, projectileHeight: int = -1) -> float:
    var height: TowerDefenseEnum.CHARACTER_HEIGHT = projectileHeight as TowerDefenseEnum.CHARACTER_HEIGHT
    var result: float = character.instance.FlagHurt(num, damageFlags, playSplatAudio, velocity, createDamagePart, isRange, height)
    BattleEventBus.characterHurt.emit(character, int(result), null)
    return result
