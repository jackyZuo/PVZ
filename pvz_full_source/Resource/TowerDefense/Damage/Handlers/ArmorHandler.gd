class_name ArmorHandler extends DamageHandler

func handle(ctx: DamageContext) -> void :
    if ctx.cancelled:
        return
    if ctx.finalDamage <= 0:
        return
    match ctx.type:
        DamageContext.DamageType.HURT:
            _process_standard_armor(ctx)
        DamageContext.DamageType.SKIP_INVINCIBLE_HURT:
            _process_skip_invincible_armor(ctx)
        DamageContext.DamageType.FLAG_HURT:
            _process_flag_armor(ctx)
        DamageContext.DamageType.EXPLODE_HURT:
            _process_explode_armor(ctx)
        DamageContext.DamageType.PROJECTILE_HURT:
            _process_flag_armor(ctx)
        DamageContext.DamageType.HURT_WITH_ATTACK_CONFIG:
            _process_standard_armor(ctx)

func _process_standard_armor(ctx: DamageContext) -> void :
    var inst = ctx.instance
    var passFlag: bool = false
    if ctx.finalDamage > 0:
        if ctx.hitShield and inst.armorShield.size() > 0:
            inst._process_armor_layer(inst.armorShield, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.DealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if inst.armorHelm.size() > 0:
            inst._process_armor_layer(inst.armorHelm, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.DealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if inst.armorBody.size() > 0:
            inst._process_armor_layer(inst.armorBody, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.DealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if ctx.finalDamage > 0:
            if !passFlag:
                ctx.finalDamage = inst.DealHurt(ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart)
    ctx.damageApplied = true
    ctx.armorPassFlag = passFlag

func _process_skip_invincible_armor(ctx: DamageContext) -> void :
    var inst = ctx.instance
    var passFlag: bool = false
    if ctx.finalDamage > 0:
        if ctx.hitShield and inst.armorShield.size() > 0:
            inst._process_armor_layer(inst.armorShield, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.SkipInvincibleDealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if inst.armorHelm.size() > 0:
            inst._process_armor_layer(inst.armorHelm, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.SkipInvincibleDealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if inst.armorBody.size() > 0:
            inst._process_armor_layer(inst.armorBody, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.SkipInvincibleDealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if ctx.finalDamage > 0:
            if !passFlag:
                ctx.finalDamage = inst.SkipInvincibleDealHurt(ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart)
    ctx.damageApplied = true
    ctx.armorPassFlag = passFlag

func _process_flag_armor(ctx: DamageContext) -> void :
    var inst = ctx.instance
    var passFlag: bool = false
    if ctx.finalDamage > 0 and (ctx.isRange or ctx.damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITHEAD_COVER):
        if inst.armorHeadCover.size() > 0:
            inst._process_armor_layer(inst.armorHeadCover, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, ctx.isRange, inst.DealHurt, ctx.projectileHeight)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
    if ctx.finalDamage > 0 and (ctx.isRange or ctx.damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD):
        if inst.armorShield.size() > 0:
            inst._process_armor_layer(inst.armorShield, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, ctx.isRange, inst.DealHurt, ctx.projectileHeight)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
    if ctx.damageFlags == TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITSHIELD:
        ctx.finalDamage = 0
        ctx.cancelled = true
        ctx.damageApplied = true
        return
    if ctx.finalDamage > 0 and ctx.damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.HITBODY:
        if ctx.damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.FIRE:
            ctx.target.buff.BuffAdd(TowerDefenseCharacterBuffFireHit.new())
        if inst.armorHelm.size() > 0:
            inst._process_armor_layer(inst.armorHelm, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.DealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
        if inst.armorBody.size() > 0:
            inst._process_armor_layer(inst.armorBody, ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart, false, inst.DealHurt)
            ctx.finalDamage = inst._armorResultNum
            passFlag = passFlag or inst._armorResultPassFlag
    if ctx.finalDamage > 0:
        if !passFlag:
            ctx.finalDamage = inst.DealHurt(ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, ctx.createDamagePart)
    ctx.damageApplied = true
    ctx.armorPassFlag = passFlag

func _process_explode_armor(ctx: DamageContext) -> void :
    var inst = ctx.instance
    for i in inst.armorHeadCover.size():
        for armor: TowerDefenseArmorInstance in inst.armorHeadCover:
            armor.DealHurt(ctx.finalDamage * armor.config.explodePersontage, ctx.playSplatAudio, ctx.velocity)
            if armor.config.explodePersontage == 0.0:
                ctx.finalDamage = 0.0
            if ctx.finalDamage > 0:
                break
        if ctx.finalDamage <= 0:
            break
    for i in inst.armorShield.size():
        for armor: TowerDefenseArmorInstance in inst.armorShield:
            armor.DealHurt(ctx.finalDamage * armor.config.explodePersontage, ctx.playSplatAudio, ctx.velocity)
            if armor.config.explodePersontage == 0.0:
                ctx.finalDamage = 0.0
            if ctx.finalDamage > 0:
                break
        if ctx.finalDamage <= 0:
            break
    for i in inst.armorHelm.size():
        for armor: TowerDefenseArmorInstance in inst.armorHelm:
            ctx.finalDamage = armor.DealHurt(ctx.finalDamage * armor.config.explodePersontage, ctx.playSplatAudio, ctx.velocity)
            if armor.config.explodePersontage == 0.0:
                ctx.finalDamage = 0.0
            if ctx.finalDamage > 0:
                break
        if ctx.finalDamage <= 0:
            break
    for i in inst.armorBody.size():
        for armor: TowerDefenseArmorInstance in inst.armorBody:
            ctx.finalDamage = armor.DealHurt(ctx.finalDamage * armor.config.explodePersontage, ctx.playSplatAudio, ctx.velocity)
            if ctx.finalDamage > 0:
                break
        if ctx.finalDamage <= 0:
            break
