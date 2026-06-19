class_name BuffModifierHandler extends DamageHandler

func handle(ctx: DamageContext) -> void :
    if ctx.cancelled:
        return
    match ctx.type:
        DamageContext.DamageType.HURT, DamageContext.DamageType.SKIP_INVINCIBLE_HURT, DamageContext.DamageType.HURT_WITH_ATTACK_CONFIG:
            ctx.finalDamage = ctx.target.buff.SetAttackNum(ctx.finalDamage)
        DamageContext.DamageType.PROJECTILE_HURT:
            pass
        DamageContext.DamageType.FLAG_HURT:
            ctx.finalDamage = ctx.target.buff.SetAttackNum(ctx.finalDamage)
            if ctx.damageFlags & TowerDefenseEnum.PROJECTILE_DAMAGE_FLAG.FIRE:
                if ctx.target.buff.BuffHas("RedHeat"):
                    ctx.finalDamage *= 2
        DamageContext.DamageType.EXPLODE_HURT:
            if ctx.explodeType == "Jala":
                ctx.target.buff.BuffAdd(TowerDefenseCharacterBuffFireHit.new())
                if ctx.target.buff.BuffHas("RedHeat"):
                    ctx.finalDamage *= 2
