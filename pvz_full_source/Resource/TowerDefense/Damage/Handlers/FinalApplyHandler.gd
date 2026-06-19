class_name FinalApplyHandler extends DamageHandler

func handle(ctx: DamageContext) -> void :
    if ctx.cancelled:
        return
    match ctx.type:
        DamageContext.DamageType.HURT, DamageContext.DamageType.SKIP_INVINCIBLE_HURT, DamageContext.DamageType.HURT_WITH_ATTACK_CONFIG:
            ctx.resultDamage = ctx.finalDamage
        DamageContext.DamageType.SMASH_HURT:
            ctx.resultDamage = ctx.finalDamage
        DamageContext.DamageType.FLAG_HURT:
            ctx.resultDamage = ctx.finalDamage
        DamageContext.DamageType.EXPLODE_HURT:
            _apply_explode(ctx)
        DamageContext.DamageType.PROJECTILE_HURT:
            ctx.resultDamage = ctx.finalDamage
    BattleEventBus.characterHurt.emit(ctx.target, int(ctx.finalDamage), ctx.projectile)

func _apply_explode(ctx: DamageContext) -> void :
    var inst = ctx.instance
    var createDamagePart: bool = true
    match ctx.explodeType:
        "Bomb":
            createDamagePart = false
        "Jala":
            createDamagePart = false
        "Mine":
            createDamagePart = false
    if ctx.finalDamage != 0:
        ctx.finalDamage = inst.DealHurt(ctx.finalDamage, ctx.playSplatAudio, ctx.velocity, createDamagePart)
    if ctx.finalDamage > 0:
        inst.hitpointsNearDie.emit()
        inst.nearDie = true
        inst.Die()
        var checkAsh: bool = true
        if ctx.target is TowerDefenseZombie:
            if inst.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                checkAsh = false
        if checkAsh:
            match ctx.explodeType:
                "Bomb":
                    if !ctx.target.inWater:
                        if inst.ashScene:
                            var effect = TowerDefenseManager.CreateEffectSpriteOnce(inst.ashScene, ctx.target.gridPos, "Idle")
                            var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                            effect.global_position = ctx.target.sprite.global_position
                            effect.scale = ctx.target.scale * ctx.target.transformPoint.scale
                            charaterNode.add_child(effect)
                            effect.z_index -= 6
                    ctx.target.Destroy()
                "Jala":
                    if inst.zombiePhysique != TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                        if !ctx.target.inWater:
                            if inst.ashScene:
                                var effect = TowerDefenseManager.CreateEffectSpriteOnce(inst.ashScene, ctx.target.gridPos, "Idle")
                                var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                                effect.global_position = ctx.target.sprite.global_position
                                effect.scale = ctx.target.scale * ctx.target.transformPoint.scale
                                charaterNode.add_child(effect)
                                effect.z_index -= 6
                        ctx.target.Destroy()
                "Mine":
                    if !ctx.target.inWater:
                        if inst.ashScene:
                            var effect = TowerDefenseManager.CreateEffectSpriteOnce(inst.ashScene, ctx.target.gridPos, "Idle")
                            var charaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
                            effect.global_position = ctx.target.sprite.global_position
                            effect.scale = ctx.target.scale * ctx.target.transformPoint.scale
                            charaterNode.add_child(effect)
                            effect.z_index -= 6
                    ctx.target.Destroy()
    ctx.target.isExplode = false
    ctx.resultDamage = ctx.finalDamage
