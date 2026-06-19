class_name DamageModifierHandler extends DamageHandler

func handle(ctx: DamageContext) -> void :
    ctx.finalDamage = ctx.baseDamage
    match ctx.type:
        DamageContext.DamageType.HURT, DamageContext.DamageType.SKIP_INVINCIBLE_HURT:
            ctx.finalDamage *= ctx.instance.dealHurtScale
        DamageContext.DamageType.SMASH_HURT:
            ctx.finalDamage *= ctx.instance.dealHurtScale
            if ctx.target is TowerDefensePlant:
                ctx.finalDamage = 100000.0
            if ctx.instance.smashHurt != -1:
                ctx.finalDamage = min(ctx.instance.smashHurt, ctx.finalDamage)
        DamageContext.DamageType.EXPLODE_HURT:
            ctx.finalDamage *= ctx.instance.dealHurtScale
            if ctx.target is TowerDefensePlant:
                if ctx.finalDamage >= 1800:
                    ctx.finalDamage = 10000000.0
            if ctx.instance.explosionHurt != -1:
                ctx.finalDamage = min(ctx.instance.explosionHurt, ctx.finalDamage)
        DamageContext.DamageType.PROJECTILE_HURT:
            if is_instance_valid(ctx.projectile):
                ctx.finalDamage = ctx.projectile.damage
                ctx.damageFlags = ctx.projectile.damageFlags
            else:
                ctx.finalDamage = ctx.projectileConfig.baseDamage
                ctx.damageFlags = ctx.projectileConfig.damageFlags
            if ctx.instance.isChests:
                ctx.finalDamage *= ctx.projectileConfig.hitChestsScale
            if ctx.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.NUT:
                ctx.finalDamage *= ctx.projectileConfig.hitNutScale
            if ctx.target.buff.BuffHas("Frozen"):
                ctx.finalDamage *= ctx.projectileConfig.hitFrozenScale
            if ctx.isRange:
                ctx.finalDamage *= ctx.projectileConfig.hitPesontage
            ctx.finalDamage *= ctx.instance.dealHurtScale
        DamageContext.DamageType.HURT_WITH_ATTACK_CONFIG:
            if ctx.instance.armorList.size() > 0:
                ctx.finalDamage = ctx.attackConfig.num * ctx.attackConfig.armorAttackScale
            else:
                ctx.finalDamage = ctx.attackConfig.num * ctx.attackConfig.attackScale
            ctx.damageFlags = ctx.attackConfig.damageFlags
