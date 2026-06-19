@tool
extends TowerDefenseZombie

@onready var attackComponent2: AttackComponent = %AttackComponent2
@onready var potNode: Node2D = %PotNode
@onready var plantNode: Node2D = %PlantNode

var canBarrow: bool = true
var hasBarrow: bool = true
var barrowPlant: TowerDefenseCharacter
var barrowPlantTranform: Transform2D
var over: bool = false
var isPlant: bool = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if is_instance_valid(barrowPlant):
        barrowPlant.gridPos.x = gridPos.x
        barrowPlant.global_position.x = potNode.global_position.x
        barrowPlant.groundHeight = (potNode.global_position.y - global_position.y) / transformPoint.global_scale.y

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func WalkProcessing(delta: float) -> void :
    if hasBarrow:
        if attackComponent2.CanAttack():
            if attackComponent2.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
                if is_instance_valid(attackComponent2.target.cell):
                    if attackComponent2.target.cell.HasSpike():
                        attackComponent2.target = attackComponent2.target.cell.GetSpike()
                if attackComponent2.target.instance.spikeHurt != -1:
                    attackComponent2.target.Hurt(attackComponent2.target.instance.spikeHurt)
                    instance.ArmorDelete("Barrow")
                    return
    if hasBarrow && canBarrow && !is_instance_valid(barrowPlant):
        if attackComponent2.CanAttack():
            if !attackComponent2.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
                var characterList = attackComponent2.GetTargetList()
                for character: TowerDefenseCharacter in characterList:
                    if !(character is TowerDefensePlant):
                        continue
                    if character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.GROUND) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.POT) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.LILYPAD) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SOIL) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.BRICK) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SURROUND):
                        if is_instance_valid(character.cell):
                            if is_instance_valid(character.cell.characterSlotDictionary[character]):
                                continue
                        Barrow(character)
                        scale.x = - scale.x
                        break
    super.WalkProcessing(delta)
    if !is_instance_valid(barrowPlant):
        sprite.timeScale = timeScale * walkSpeedScale * 2.0

func AttackProcessing(delta: float) -> void :
    if hasBarrow:
        if attackComponent2.CanAttack():
            if attackComponent2.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
                if attackComponent2.target.instance.spikeHurt != -1:
                    attackComponent2.target.Hurt(attackComponent2.target.instance.spikeHurt)
                    instance.ArmorDelete("Barrow")
                    return
    if hasBarrow && canBarrow && !is_instance_valid(barrowPlant):
        if attackComponent2.CanAttack():
            if !attackComponent2.target.instance.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE:
                var characterList = attackComponent2.GetTargetList()
                for character: TowerDefenseCharacter in characterList:
                    if !(character is TowerDefensePlant):
                        continue
                    if character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.GROUND) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.POT) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.LILYPAD) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SOIL) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.BRICK) || \
character.config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.SURROUND):
                        if is_instance_valid(character.cell):
                            if is_instance_valid(character.cell.characterSlotDictionary[character]):
                                continue
                        Barrow(character)
                        scale.x = - scale.x
                        break
    super.AttackProcessing(delta)

func ArmorHitpointsEmpty(armorName: String) -> void :
    super.ArmorHitpointsEmpty(armorName)
    match armorName:
        "Barrow":
            useAttackDps = true
            hasBarrow = false
            canBarrow = false
            walkAnimeClip = "Walk"
            swimAnimeClip = "Walk"
            attackAnimeClip = "Eat"
            attackComponent.checkVase = false
            attackComponent.attackType = "Eat"
            Walk()
            instance.collisionFlags = TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.GROUND_CHARACTRE
            if !isPlant:
                isPlant = true
                Plant()

func DestroySet() -> void :
    if over:
        return
    over = true
    await Plant()
    await get_tree().physics_frame

func Barrow(character: TowerDefenseCharacter) -> void :
    canBarrow = false
    barrowPlant = character

    var plantCell: TowerDefenseCellInstance = barrowPlant.cell
    if is_instance_valid(plantCell):
        var getTarget = plantCell.GetTarget(instance.maskFlags, camp)
        if is_instance_valid(getTarget):
            barrowPlant = getTarget
        if is_instance_valid(barrowPlant):
            plantCell.CharacterDestroy(barrowPlant)
    barrowPlantTranform = barrowPlant.transform
    barrowPlant.hitBox.process_mode = Node.PROCESS_MODE_DISABLED
    barrowPlant.gridPos.x = -1
    barrowPlant.reparent(plantNode, true)

    barrowPlant.shadowSprite.visible = false
    barrowPlant.scale.y = sign(barrowPlant.scale.y) * barrowPlant.scale.y
    barrowPlant.rotation = 0.0
    barrowPlant.position = Vector2.ZERO
    barrowPlant.destroy.emit(barrowPlant)

func Plant() -> void :
    if !is_instance_valid(barrowPlant):
        return
    if !is_instance_valid(cell):
        barrowPlant.Destroy()
        return
    if !cell.CanPacketPlant(barrowPlant.packet):
        barrowPlant.Destroy()
        return
    cell.CharacterPlant(barrowPlant.packet, barrowPlant)
    if is_instance_valid(barrowPlant.hitBox):
        barrowPlant.hitBox.process_mode = Node.PROCESS_MODE_INHERIT
    barrowPlant.gridPos = gridPos
    barrowPlant.reparent(characterNode)
    barrowPlant.rotation = barrowPlantTranform.get_rotation()
    barrowPlant.scale = barrowPlantTranform.get_scale()
    barrowPlant.shadowSprite.visible = !barrowPlant.invisible
    if barrowPlant.scale.y < 0:
        barrowPlant.scale.y = - barrowPlant.scale.y
        barrowPlant.rotation_degrees -= 180
    barrowPlant.global_position = TowerDefenseManager.GetMapCellPlantPos(gridPos)
    barrowPlant.shadowComponent.saveShadowPosition.x = barrowPlant.global_position.x
    barrowPlant.shadowSprite.global_position.x = barrowPlant.global_position.x
    if is_instance_valid(barrowPlant):
        barrowPlant.groundHeight = 0
        barrowPlant.shadowSprite.visible = !barrowPlant.invisible
        barrowPlant = null
    await get_tree().physics_frame

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)
    match command:
        "attack":
            attackComponent.Attack(config.smashAttack)
