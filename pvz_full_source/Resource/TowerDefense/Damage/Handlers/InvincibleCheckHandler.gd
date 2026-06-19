class_name InvincibleCheckHandler extends DamageHandler

func handle(ctx: DamageContext) -> void :
    if ctx.instance.die:
        ctx.resultDamage = 1000000.0
        ctx.cancelled = true
        return
    if CommandManager.debug && CommandManager.debugPlantInvincible && ctx.target is TowerDefensePlant:
        ctx.target.bodyHurt.emit(0)
        ctx.resultDamage = 0.0
        ctx.cancelled = true
        return
    if CommandManager.debug && CommandManager.debugBrainInvincible && ctx.target.is_in_group("Brain"):
        ctx.target.bodyHurt.emit(0)
        ctx.resultDamage = 0.0
        ctx.cancelled = true
        return
    match ctx.type:
        DamageContext.DamageType.HURT:
            if ctx.instance.invincible:
                ctx.target.bodyHurt.emit(0)
                ctx.resultDamage = 0.0
                ctx.cancelled = true
                return
            if ctx.instance.invincibleHurt:
                ctx.resultDamage = 0.0
                ctx.cancelled = true
                return
        DamageContext.DamageType.FLAG_HURT:
            if ctx.instance.invincible:
                ctx.target.bodyHurt.emit(0)
                ctx.resultDamage = 0.0
                ctx.cancelled = true
                return
        DamageContext.DamageType.SMASH_HURT:
            if ctx.instance.invincible:
                ctx.target.bodyHurt.emit(0)
                ctx.resultDamage = 0.0
                ctx.cancelled = true
                return
            if ctx.instance.invincibleSmash:
                ctx.resultDamage = 0.0
                ctx.cancelled = true
                return
        DamageContext.DamageType.EXPLODE_HURT:
            if ctx.instance.invincible:
                ctx.target.bodyHurt.emit(0)
                ctx.resultDamage = 0.0
                ctx.cancelled = true
                return
        DamageContext.DamageType.PROJECTILE_HURT:
            if ctx.instance.die:
                ctx.resultDamage = 1000000.0
                ctx.cancelled = true
                return
        DamageContext.DamageType.SKIP_INVINCIBLE_HURT:
            if ctx.instance.die:
                ctx.resultDamage = 1000000.0
                ctx.cancelled = true
                return
