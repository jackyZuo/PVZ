class_name TowerDefenseCharacterInstance extends Resource

var character: TowerDefenseCharacter
@export_storage var config: TowerDefenseCharacterConfig

@export_storage var zombiePhysique: TowerDefenseEnum.ZOMBIE_PHYSIQUE = TowerDefenseEnum.ZOMBIE_PHYSIQUE.NORMAL

@export_storage var explosionHurt: float = -1.0
@export_storage var smashHurt: float = -1.0
@export_storage var dragHurt: float = -1.0
@export_storage var spikeHurt: float = -1.0
@export_storage var biteHurt: float = -1.0

var explosionHurtSave: float = -1.0

@export_storage var hitpointsSave: float = 200.0
@export_storage var hitpoints: float = 200.0
@export_storage var height: TowerDefenseEnum.CHARACTER_HEIGHT = TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL
@export_storage var collisionFlags: int = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
@export_storage var maskFlags: int = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
@export_storage var unUseBuffFlags: int = 0
@export_storage var physiqueTypeFlags: int = 0
@export_storage var elementFlags: int = 0
@export_storage var hitpointsNearDeath: float = 0.0
@export_storage var hitpointsBase: float = 300.0
@export_storage var impactAudio: String = ""
@export_storage var ashScene: PackedScene
@export_storage var armorData: CharacterArmorData
@export_storage var customData: CharacterCustomData
@export_storage var isChests: bool = false
@export_storage var dealHurtScale: float = 1.0

@export_storage var damagePointData: CharacterDamagePointData
@export_storage var damagePoints: Array[Dictionary] = []
@export_storage var damagePointIndex = 0

@export_storage var canCollection: bool = true
@export_storage var canBeCollection: bool = true
@export_storage var keepArmor: bool = false
@export_storage var keepAlive: bool = false

@export_storage var die: bool = false
@export_storage var nearDie: bool = false
@export_storage var invincible: bool = false
@export_storage var invincibleHurt: bool = false
@export_storage var invincibleSmash: bool = false
@export_storage var sleep: bool = false
@export_storage var wakeUp: bool = false
@export_storage var hypnoses: bool = false
@export_storage var hologram: bool = false

@export_storage var hitpointScaleSave: float = 1.0

@export_storage var hitpointScale: float = 1.0:
    set(_hitpointScale):
        hitpointScale = _hitpointScale
        hitpointsSave *= _hitpointScale / hitpointScaleSave
        hitpoints *= _hitpointScale / hitpointScaleSave
        for armor in armorList:
            if !armor.isRemove:
                armor.hitpointScale = hitpointScale
        hitpointScaleSave = hitpointScale

@export_storage var armorOverrideUnUseBuffFlagSave: int = 0

@export_storage var armorList: Array[TowerDefenseArmorInstance] = []
@export_storage var armorShield: Array[TowerDefenseArmorInstance] = []
@export_storage var armorHelm: Array[TowerDefenseArmorInstance] = []
@export_storage var armorBody: Array[TowerDefenseArmorInstance] = []
@export_storage var armorHeadCover: Array[TowerDefenseArmorInstance] = []

signal damagePointReach(name: String)
signal armorDamagePointReach(name: String, stage: int)
signal hitpointsNearDie()
signal hitpointsEmpty()
signal armorHitpointsEmpty()

func _init(_character: TowerDefenseCharacter, _config: TowerDefenseCharacterConfig) -> void :
    character = _character
    config = _config

    explosionHurt = config.explosionHurt
    explosionHurtSave = config.explosionHurt
    smashHurt = config.smashHurt
    dragHurt = config.dragHurt
    spikeHurt = config.spikeHurt
    biteHurt = config.biteHurt

    hitpointsNearDeath = config.hitpointsNearDeath
    hitpointsBase = config.hitpoints
    hitpoints = hitpointsBase + hitpointsNearDeath
    hitpointsSave = hitpoints
    height = config.height
    ashScene = config.ashScene
    armorData = config.armorData
    customData = config.customData

    collisionFlags = config.collisionFlags
    maskFlags = config.maskFlags
    unUseBuffFlags = config.unUseBuffFlags
    physiqueTypeFlags = config.physiqueTypeFlags
    elementFlags = config.elementFlags

    damagePointData = config.damagePointData
    if damagePointData:
        for damagePointConfig: CharacterDamagePointConfig in damagePointData.damagePointList:
            var damageDictionary: Dictionary = {}
            damageDictionary["Persontage"] = damagePointConfig.damagePersontage
            damageDictionary["Name"] = damagePointConfig.damagePointName
            damageDictionary["DamageAudio"] = damagePointConfig.damageAudio
            damagePoints.append(damageDictionary)

    if _config is TowerDefenseZombieConfig:
        zombiePhysique = _config.physique
        impactAudio = _config.impactAudio
    if _config is TowerDefenseGravestoneConfig:
        isChests = _config.isChests

    for armorName: String in character.currentArmor:
        ArmorAdd(armorName)

var _armorResultNum: float = 0.0
var _armorResultPassFlag: bool = false

func _process_armor_layer(armor_list: Array[TowerDefenseArmorInstance], num: float, playSplatAudio: bool, velocity: Vector2, createDamagePart: bool, isRange: bool, dealHurtFunc: Callable, projectileHeight: int = -1) -> void :
    var passFlag: bool = false
    for armorInstance: TowerDefenseArmorInstance in armor_list:
        if armorInstance.isRemove:
            continue
        if projectileHeight >= 0 && projectileHeight > armorInstance.typeData.height:
            continue
        if armorInstance.typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.INVINCIBLE:
            num = 0
        if armorInstance.typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.PASSDAMAGE:
            dealHurtFunc.call(num, playSplatAudio, velocity, createDamagePart)
            passFlag = true
        if isRange:
            armorInstance.Hurt(num, playSplatAudio, velocity, createDamagePart)
        else:
            num = armorInstance.Hurt(num, playSplatAudio, velocity, createDamagePart)
        if num <= 0:
            break
    _armorResultNum = num
    _armorResultPassFlag = passFlag

func HurtWithAttackConfig(attackConfig: AttackConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    if armorList.size() > 0:
        return FlagHurt(attackConfig.num * attackConfig.armorAttackScale, attackConfig.damageFlags, playSplatAudio, velocity, createDamagePart)
    else:
        return FlagHurt(attackConfig.num * attackConfig.attackScale, attackConfig.damageFlags, playSplatAudio, velocity, createDamagePart)

func ProjectileHurt(projectile: TowerDefenseProjectile, projectileConfig: TowerDefenseProjectileConfig, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, isRange: bool = false, createDamagePart: bool = true) -> float:
    if die:
        return 1000000.0
    var num: float = projectileConfig.baseDamage
    var damageFlags: int = projectileConfig.damageFlags
    if is_instance_valid(projectile):
        num = projectile.damage
        damageFlags = projectile.damageFlags
    var hitShieldFlag: bool = false
    if isChests:
        num *= projectileConfig.hitChestsScale

    if physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
        num *= projectileConfig.hitNutScale

    if character.buff.BuffHas("Frozen"):
        num *= projectileConfig.hitFrozenScale

    if isRange:
        num *= projectileConfig.hitPesontage
    else:
        if projectileConfig.useRange:
            if !(damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD):
                hitShieldFlag = true
    if projectileConfig.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.PENETRATE:
        hitShieldFlag = true
        if is_instance_valid(projectile):
            for armor in armorList:
                if !armor.isRemove and armor.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.CANT_PENETRATE:
                    projectile.Over()
                    if !(damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD):
                        damageFlags |= TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
                        hitShieldFlag = false
            if character.config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.CANT_PENETRATE:
                projectile.Over()
                if !(damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD):
                    damageFlags |= TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
                    hitShieldFlag = false
    if hitShieldFlag:
        FlagHurt(num, TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD, playSplatAudio, velocity, createDamagePart, isRange)
    if is_instance_valid(projectile):
        if projectileConfig.fireMethodFlags & TowerDefenseEnum.PROJECTILE_FIRE_METHOD_FLAG.SHOOTER:
            if (projectile.global_position.x > character.global_position.x + 30 && character.scale.x > 0) || \
(projectile.global_position.x < character.global_position.x - 30 && character.scale.x < 0):
                damageFlags ^= TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD
    match projectileConfig.rangeType:
        "Default":
            if is_instance_valid(projectile):
                return FlagHurt(num, damageFlags, playSplatAudio, velocity, createDamagePart, isRange, projectile.projectileHeight)
            else:
                return FlagHurt(num, damageFlags, playSplatAudio, velocity, createDamagePart, isRange)
        "Bomb":
            return ExplodeHurt(num, projectileConfig.rangeType, playSplatAudio, velocity)
    return FlagHurt(num, damageFlags, playSplatAudio, velocity, createDamagePart, isRange)

func FlagHurt(num: float, damageFlags: int, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true, isRange: bool = false, projectileHeight: TowerDefenseEnum.CHARACTER_HEIGHT = TowerDefenseEnum.CHARACTER_HEIGHT.NORMAL) -> float:
    if invincible:
        character.bodyHurt.emit(0)
        return 0
    if die:
        return 1000000.0
    num = character.buff.SetAttackNum(num)
    num *= dealHurtScale

    num = _ShieldAbsorb(num)
    if num <= 0:
        return 0
    var passFlag: bool = false
    if damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.FIRE:
        if character.buff.BuffHas("RedHeat"):
            num *= 2
    if num > 0 && (isRange || damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITHEAD_COVER):
        if armorHeadCover.size() > 0:
            _process_armor_layer(armorHeadCover, num, playSplatAudio, velocity, createDamagePart, isRange, DealHurt, projectileHeight)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
    if num > 0 && (isRange || damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD):
        if armorShield.size() > 0:
            _process_armor_layer(armorShield, num, playSplatAudio, velocity, createDamagePart, isRange, DealHurt, projectileHeight)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
    if damageFlags == TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD:
        return 0
    if num > 0 && damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY:
        if damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.FIRE:
            character.buff.BuffAdd(TowerDefenseCharacterBuffFireHit.new())
        if armorHelm.size() > 0:
            _process_armor_layer(armorHelm, num, playSplatAudio, velocity, createDamagePart, false, DealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if armorBody.size() > 0:
            _process_armor_layer(armorBody, num, playSplatAudio, velocity, createDamagePart, false, DealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
    if num > 0:
        if !passFlag:
            num = DealHurt(num, playSplatAudio, velocity, createDamagePart)
    return num

func ExplodeHurt(num: float, type: String = "Bomb", playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    if invincible:
        character.bodyHurt.emit(0)
        return 0
    num *= dealHurtScale

    if character is TowerDefensePlant:
        if num >= 1800 && is_instance_valid(character.cell) && is_instance_valid(character.cell.itemShield):
            if character.cell.itemShield.ShieldBlockLethal():
                return 0
    if character is TowerDefensePlant:
        if num >= 1800:
            num = 10000000
    if explosionHurt != -1:
        num = min(explosionHurt, num)
    if character is TowerDefensePlant:
        if is_instance_valid(character.cell):
            var slotCharacter: TowerDefenseCharacter = character.cell.GetSlot(character)
            if is_instance_valid(slotCharacter):
                if slotCharacter.instance.hitpoints - num > 0 && character.instance.hitpoints - num <= 0:
                    return num

    if type == "Jala":
        character.buff.BuffAdd(TowerDefenseCharacterBuffFireHit.new())
        if character.buff.BuffHas("RedHeat"):
            num *= 2
    for i in armorHeadCover.size():
        for armor: TowerDefenseArmorInstance in armorHeadCover:
            armor.DealHurt(num * armor.typeData.explodePersontage, playSplatAudio, velocity)
            if armor.typeData.explodePersontage == 0.0:
                num = 0.0
            if num > 0:
                break
        if num <= 0:
            break
    for i in armorShield.size():
        for armor: TowerDefenseArmorInstance in armorShield:
            armor.DealHurt(num * armor.typeData.explodePersontage, playSplatAudio, velocity)
            if armor.typeData.explodePersontage == 0.0:
                num = 0.0
            if num > 0:
                break
        if num <= 0:
            break
    for i in armorHelm.size():
        for armor: TowerDefenseArmorInstance in armorHelm:
            num = armor.DealHurt(num * armor.typeData.explodePersontage, playSplatAudio, velocity)
            if armor.typeData.explodePersontage == 0.0:
                num = 0.0
            if num > 0:
                break
        if num <= 0:
            break
    for i in armorBody.size():
        for armor: TowerDefenseArmorInstance in armorBody:
            num = armor.DealHurt(num * armor.typeData.explodePersontage, playSplatAudio, velocity)
            if num > 0:
                break
        if num <= 0:
            break
    var createDamagePart: bool = true
    match type:
        "Bomb":
            createDamagePart = false
        "Jala":
            createDamagePart = false
        "Mine":
            createDamagePart = false
    if num != 0:
        num = DealHurt(num, playSplatAudio, velocity, createDamagePart)
    if num > 0:
        hitpointsNearDie.emit()
        nearDie = true
        if !(Global.isMultiplayerMode and !MultiPlayerManager.isHost and character is TowerDefensePlant):
            Die()
        var checkAsh: bool = true
        if character is TowerDefenseZombie:
            if zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                checkAsh = false

        if checkAsh:
            match type:
                "Bomb":
                    if !character.inWater:
                        if ashScene:
                            var effect = TowerDefenseManager.CreateEffectSpriteOnce(ashScene, character.gridPos, "Idle")
                            var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                            effect.global_position = character.sprite.global_position
                            effect.scale = character.scale * character.transformPoint.scale
                            charaterNode.add_child(effect)
                            effect.z_index -= 6
                    character.Destroy()
                "Jala":
                    if zombiePhysique != TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                        if !character.inWater:
                            if ashScene:
                                var effect = TowerDefenseManager.CreateEffectSpriteOnce(ashScene, character.gridPos, "Idle")
                                var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                                effect.global_position = character.sprite.global_position
                                effect.scale = character.scale * character.transformPoint.scale
                                charaterNode.add_child(effect)
                                effect.z_index -= 6
                        character.Destroy()
                "Mine":
                    if !character.inWater:
                        if ashScene:
                            var effect = TowerDefenseManager.CreateEffectSpriteOnce(ashScene, character.gridPos, "Idle")
                            var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                            effect.global_position = character.sprite.global_position
                            effect.scale = character.scale * character.transformPoint.scale
                            charaterNode.add_child(effect)
                            effect.z_index -= 6
                    character.Destroy()
    return num

func SkipInvincibleHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, hitShield: bool = true, createDamagePart: bool = true) -> float:
    if die:
        return 1000000.0
    num *= dealHurtScale

    num = _ShieldAbsorb(num)
    if num <= 0:
        return 0
    var passFlag: bool = false
    if num > 0:
        if hitShield && armorShield.size() > 0:
            _process_armor_layer(armorShield, num, playSplatAudio, velocity, createDamagePart, false, SkipInvincibleDealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if armorHelm.size() > 0:
            _process_armor_layer(armorHelm, num, playSplatAudio, velocity, createDamagePart, false, SkipInvincibleDealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if armorBody.size() > 0:
            _process_armor_layer(armorBody, num, playSplatAudio, velocity, createDamagePart, false, SkipInvincibleDealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if num > 0:
            if !passFlag:
                num = SkipInvincibleDealHurt(num, playSplatAudio, velocity, createDamagePart)
    return num



func _ShieldAbsorb(num: float) -> float:
    if num <= 0:
        return num
    if character is TowerDefensePlant:
        if is_instance_valid(character.cell) && is_instance_valid(character.cell.itemShield):
            return character.cell.itemShield.ShieldAbsorbDamage(num)
    return num

func Hurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, hitShield: bool = true, createDamagePart: bool = true) -> float:
    if invincible:
        character.bodyHurt.emit(0)
        return 0
    if invincibleHurt:
        return 0
    if die:
        return 1000000.0
    num *= dealHurtScale

    num = _ShieldAbsorb(num)
    if num <= 0:
        return 0
    var passFlag: bool = false
    if num > 0:
        if hitShield && armorShield.size() > 0:
            _process_armor_layer(armorShield, num, playSplatAudio, velocity, createDamagePart, false, DealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if armorHelm.size() > 0:
            _process_armor_layer(armorHelm, num, playSplatAudio, velocity, createDamagePart, false, DealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if armorBody.size() > 0:
            _process_armor_layer(armorBody, num, playSplatAudio, velocity, createDamagePart, false, DealHurt)
            num = _armorResultNum
            passFlag = passFlag || _armorResultPassFlag
        if num > 0:
            if !passFlag:
                num = DealHurt(num, playSplatAudio, velocity, createDamagePart)
    return num

func SmashHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO) -> float:
    if invincible:
        character.bodyHurt.emit(0)
        return 0
    if invincibleSmash:
        return 0

    if character is TowerDefensePlant:
        if is_instance_valid(character.cell) && is_instance_valid(character.cell.itemShield):
            if character.cell.itemShield.ShieldBlockLethal():
                character.cell.itemShield.ShieldDeflateVehicle(character.lastAttacker)
                return 0
    if character is TowerDefensePlant:
        var checkNum: float = 100000.0
        if smashHurt != -1:
            checkNum = min(smashHurt, checkNum)
        if is_instance_valid(character.cell):
            var slotCharacter: TowerDefenseCharacter = character.cell.GetSlot(character)
            if is_instance_valid(slotCharacter):
                if slotCharacter.instance.hitpoints - checkNum > 0 && character.instance.hitpoints - checkNum <= 0:
                    return num

    character.isSmash = true
    if character is TowerDefensePlant:
        num = 100000
    if smashHurt != -1:
        num = Hurt(min(smashHurt, num), playSplatAudio, velocity)
    else:
        num = Hurt(num, playSplatAudio, velocity)
    character.isSmash = false
    return num

func SkipInvincibleDealHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and character is TowerDefenseZombie:
        return num
    if character is TowerDefenseZombie:
        if playSplatAudio:
            if impactAudio != "":
                AudioManager.AudioPlay(impactAudio, AudioManagerEnum.TYPE.SFX)
            else:
                AudioManager.AudioPlay("SplatNormal", AudioManagerEnum.TYPE.SFX)

    if hitpoints > num:
        character.bodyHurt.emit(num)
        hitpoints -= num
        num = 0
    else:
        character.bodyHurt.emit(hitpoints)
        num -= hitpoints
        hitpoints = 0
    if damagePointData:
        var persontage: float = (hitpoints - hitpointsNearDeath) / (hitpointsSave - hitpointsNearDeath)
        if damagePointIndex < damagePoints.size():
            while persontage <= damagePoints[damagePointIndex]["Persontage"]:
                var damagePointName: String = damagePoints[damagePointIndex]["Name"]
                var damageAudio: String = damagePoints[damagePointIndex]["DamageAudio"]
                if createDamagePart:
                    if velocity == Vector2.ZERO:
                        velocity = Vector2(randf_range(-100, 100) * randf_range(0.75, 1.25), -300 * randf_range(0.75, 1.25))
                    else:
                        velocity = Vector2(velocity.x * randf_range(0.75, 1.25), velocity.y * randf_range(0.75, 1.25))
                    character.DamagePartCreate(damagePointName, null, velocity)
                damagePointData.CreateEffect(character.sprite, damagePointName, character.gridPos)
                if playSplatAudio && damageAudio != "":
                    AudioManager.AudioPlay(damageAudio, AudioManagerEnum.TYPE.SFX)
                SetDamageStage(damagePointIndex)
                damagePointIndex += 1
                if damagePointIndex >= damagePoints.size():
                    break
    if !nearDie:
        if hitpoints <= hitpointsNearDeath:
            if !keepArmor:
                ArmorClear()
            hitpointsNearDie.emit()
            nearDie = true
    if !keepAlive:
        if hitpoints <= 0:
            if Global.isMultiplayerMode and !MultiPlayerManager.isHost and character is TowerDefensePlant:
                hitpoints = 1
                return num
            elif Global.isMultiplayerMode and !MultiPlayerManager.isHost and character is TowerDefenseZombie:
                hitpoints = 1
            else:
                Die()
            hitpointsEmpty.emit()
    return num

func DealHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true) -> float:
    if invincible:
        character.bodyHurt.emit(0)
        return 0
    return SkipInvincibleDealHurt(num, playSplatAudio, velocity, createDamagePart)

func Health(num: float) -> void :
    hitpoints += num
    RefreshDamagePoint()

func ArmorHas(armorName: String) -> bool:
    for armorInstance: TowerDefenseArmorInstance in armorList:
        if armorInstance.slotConfig.armorName == armorName:
            return true
    return false

func ArmorAdd(armorName: String) -> void :
    if armorName == "SpecialHelmet":
        armorOverrideUnUseBuffFlagSave = unUseBuffFlags
        unUseBuffFlags = TowerDefenseEnum.CHARACTER_BUFF_FLAGS.ALL
    if !is_instance_valid(armorData):
        return
    var slotConfig: ArmorSlotConfig = armorData.GetOrCreateSlotConfig(armorName)
    if !slotConfig:
        return
    var typeData: TowerDefenseArmorTypeData = TowerDefenseArmorRegistry.GetArmorType(armorName)
    var armorInstance: TowerDefenseArmorInstance = TowerDefenseArmorInstance.new(character, slotConfig)
    armorInstance.remove.connect(ArmorDestroy)
    armorInstance.hitpointsEmpty.connect(ArmorDestroy)
    armorInstance.damagePointReach.connect(ArmorDamagePointReach)
    armorInstance.hitpointScale = hitpointScale
    armorList.append(armorInstance)
    if typeData && typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.SHIELD:
        armorShield.append(armorInstance)
    if typeData && typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.HELM:
        armorHelm.append(armorInstance)
    if typeData && typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.BODY:
        armorBody.append(armorInstance)
    if typeData && typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.HEAD_COVER:
        armorHeadCover.append(armorInstance)
    if typeData && typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE:
        if !character.damagePart.has(armorName):
            character.damagePart[armorName] = slotConfig

func ArmorDelete(armorName: String, createDamagePart: bool = true) -> void :
    for armorInstance: TowerDefenseArmorInstance in armorList:
        if armorInstance.slotConfig.armorName == armorName:
            armorInstance.Hurt(10000000.0, false, Vector2.ZERO, createDamagePart)

func ArmorDamagePointReach(instance: TowerDefenseArmorInstance, stage: int):
    armorDamagePointReach.emit(instance.slotConfig.armorName, stage)

func ArmorDestroy(instance: TowerDefenseArmorInstance) -> void :
    if instance.slotConfig.armorName == "SpecialHelmet":
        unUseBuffFlags = armorOverrideUnUseBuffFlagSave
    instance.isRemove = true
    armorList.erase(instance)
    armorShield.erase(instance)
    armorHelm.erase(instance)
    armorBody.erase(instance)
    armorHeadCover.erase(instance)
    armorHitpointsEmpty.emit(instance.slotConfig.armorName)

func ArmorClear() -> void :
    for armorInstance: TowerDefenseArmorInstance in armorList.duplicate():
        armorInstance.Hurt(10000000.0, false, Vector2.ZERO, true, true)

func ArmorDraw(instance: TowerDefenseArmorInstance) -> TowerDefenseMagnet:
    if !armorList.has(instance):
        return null
    var draw: TowerDefenseMagnet = instance.Draw()
    character.armorHurt.emit(instance.hitPoints)
    armorHitpointsEmpty.emit(instance.slotConfig.armorName)
    return draw

func RefeshHitPoint() -> void :
    hitpoints = hitpointsBase

func Die() -> void :
    collisionFlags = 0
    maskFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.DYING_CHARACTER
    if !keepArmor:
        ArmorClear()
    die = true

func SetDamageStage(index: int) -> void :
    var damagePointName: String = damagePoints[damagePointIndex]["Name"]
    damagePointData.SetDamagePointFliters(character.sprite, damagePointName)
    if customData:
        for customName: String in character.currentCustom:
            customData.SetDamagePoint(character.sprite, customName, index)
    damagePointReach.emit(damagePointName)

func RefreshDamagePoint() -> void :
    if !damagePointData:
        return
    if damagePointIndex == 0:
        return
    if character is TowerDefenseZombie:
        return
    if character is TowerDefenseZombieGargantuarBase:
        return
    if !is_instance_valid(character) || !is_instance_valid(character.sprite):
        return
    var persontage: float = (hitpoints - hitpointsNearDeath) / (hitpointsSave - hitpointsNearDeath)
    var newIndex: = 0
    for i in damagePoints.size():
        if persontage <= damagePoints[i]["Persontage"]:
            newIndex = i + 1
        else:
            break
    if newIndex == damagePointIndex:
        return
    damagePointData.ClearDamagePointAll(character.sprite)
    if customData:
        for customName: String in character.currentCustom:
            customData.ClearDamagePoint(character.sprite, customName)
    for i in newIndex:
        var damagePointName: String = damagePoints[i]["Name"]
        damagePointData.SetDamagePointFliters(character.sprite, damagePointName)
        if customData:
            for customName: String in character.currentCustom:
                customData.SetDamagePoint(character.sprite, customName, i)
    damagePointIndex = newIndex

func ExportSave() -> Dictionary:
    var data: Dictionary = {}
    data["hitpoints"] = hitpoints
    data["hitpointsSave"] = hitpointsSave
    data["hitpointScale"] = hitpointScale
    data["hitpointScaleSave"] = hitpointScaleSave
    data["nearDie"] = nearDie
    data["die"] = die
    data["invincible"] = invincible
    data["invincibleHurt"] = invincibleHurt
    data["invincibleSmash"] = invincibleSmash
    data["sleep"] = sleep
    data["wakeUp"] = wakeUp
    data["hypnoses"] = hypnoses
    data["hologram"] = hologram
    data["damagePointIndex"] = damagePointIndex
    data["dealHurtScale"] = dealHurtScale
    data["collisionFlags"] = collisionFlags
    data["maskFlags"] = maskFlags
    data["unUseBuffFlags"] = unUseBuffFlags
    data["armorOverrideUnUseBuffFlagSave"] = armorOverrideUnUseBuffFlagSave
    data["explosionHurt"] = explosionHurt
    data["explosionHurtSave"] = explosionHurtSave
    data["smashHurt"] = smashHurt
    data["dragHurt"] = dragHurt
    data["spikeHurt"] = spikeHurt
    data["biteHurt"] = biteHurt
    data["canCollection"] = canCollection
    data["canBeCollection"] = canBeCollection
    data["keepArmor"] = keepArmor
    data["keepAlive"] = keepAlive
    data["physiqueTypeFlags"] = physiqueTypeFlags
    data["elementFlags"] = elementFlags
    data["hitpointsNearDeath"] = hitpointsNearDeath
    data["hitpointsBase"] = hitpointsBase
    data["zombiePhysique"] = zombiePhysique
    data["height"] = height
    data["isChests"] = isChests
    var armorSaveList: Array[Dictionary] = []
    for armorInstance: TowerDefenseArmorInstance in armorList:
        if !armorInstance.isRemove:
            armorSaveList.append(armorInstance.ExportSave())
    data["armorList"] = armorSaveList
    return data

func ImportSave(data: Dictionary) -> void :
    hitpointScaleSave = data.get("hitpointScaleSave", hitpointScaleSave)
    hitpointScale = data.get("hitpointScale", hitpointScale)
    hitpointsSave = data.get("hitpointsSave", hitpointsSave)
    hitpoints = data.get("hitpoints", hitpoints)
    nearDie = data.get("nearDie", nearDie)
    die = data.get("die", die)
    invincible = data.get("invincible", invincible)
    invincibleHurt = data.get("invincibleHurt", invincibleHurt)
    invincibleSmash = data.get("invincibleSmash", invincibleSmash)
    sleep = data.get("sleep", sleep)
    wakeUp = data.get("wakeUp", wakeUp)
    hypnoses = data.get("hypnoses", hypnoses)
    hologram = data.get("hologram", hologram)
    damagePointIndex = data.get("damagePointIndex", damagePointIndex)
    dealHurtScale = data.get("dealHurtScale", dealHurtScale)
    collisionFlags = data.get("collisionFlags", collisionFlags)
    maskFlags = data.get("maskFlags", maskFlags)
    unUseBuffFlags = data.get("unUseBuffFlags", unUseBuffFlags)
    armorOverrideUnUseBuffFlagSave = data.get("armorOverrideUnUseBuffFlagSave", armorOverrideUnUseBuffFlagSave)
    explosionHurt = data.get("explosionHurt", explosionHurt)
    explosionHurtSave = data.get("explosionHurtSave", explosionHurtSave)
    smashHurt = data.get("smashHurt", smashHurt)
    dragHurt = data.get("dragHurt", dragHurt)
    spikeHurt = data.get("spikeHurt", spikeHurt)
    biteHurt = data.get("biteHurt", biteHurt)
    canCollection = data.get("canCollection", canCollection)
    canBeCollection = data.get("canBeCollection", canBeCollection)
    keepArmor = data.get("keepArmor", keepArmor)
    keepAlive = data.get("keepAlive", keepAlive)
    physiqueTypeFlags = data.get("physiqueTypeFlags", physiqueTypeFlags)
    elementFlags = data.get("elementFlags", elementFlags)
    hitpointsNearDeath = data.get("hitpointsNearDeath", hitpointsNearDeath)
    hitpointsBase = data.get("hitpointsBase", hitpointsBase)
    zombiePhysique = data.get("zombiePhysique", zombiePhysique)
    height = data.get("height", height)
    isChests = data.get("isChests", isChests)
    if data.has("armorList"):
        var armorSaveList: Array[Dictionary] = data["armorList"]
        for armorSaveData: Dictionary in armorSaveList:
            var armorName: String = armorSaveData.get("armorName", "")
            if armorName == "":
                continue
            for armorInstance: TowerDefenseArmorInstance in armorList:
                if armorInstance.slotConfig.armorName == armorName:
                    armorInstance.ImportSave(armorSaveData)
                    break
