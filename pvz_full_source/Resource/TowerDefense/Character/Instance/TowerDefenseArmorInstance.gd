class_name TowerDefenseArmorInstance extends Resource

var character: TowerDefenseCharacter
var sprite: Sprite2D = null

var typeData: TowerDefenseArmorTypeData
var slotConfig: ArmorSlotConfig

var damagePointBase: float

@export_storage var hitpointsSave: float
@export_storage var hitPoints: float
@export_storage var armorMethodFlags: int

@export_storage var stagePersontage: Array[float]
@export_storage var stageIndex: int = 0

@export_storage var isRemove: bool = false

var damagePartDropped: bool = false

@export_storage var hitpointScaleSave: float = 1.0

@export_storage var hitpointScale: float = 1.0:
    set(_hitpointScale):
        hitpointScale = _hitpointScale
        hitPoints *= _hitpointScale / hitpointScaleSave
        hitpointsSave *= _hitpointScale / hitpointScaleSave
        hitpointScaleSave = hitpointScale

signal damagePointReach(instance: TowerDefenseArmorInstance, stage: int)
signal hitpointsEmpty(instance: TowerDefenseArmorInstance)
signal remove(instance: TowerDefenseArmorInstance)

func Export() -> Dictionary:
    var data: Dictionary = {
        "slotConfig": slotConfig, 
        "hitpointsSave": hitpointsSave, 
        "hitPoints": hitPoints, 
        "armorMethodFlags": armorMethodFlags, 
        "stageIndex": stageIndex, 
        "isRemove": isRemove
    }
    return data

func ExportSave() -> Dictionary:
    var data: Dictionary = {}
    data["armorName"] = slotConfig.armorName
    data["hitpointsSave"] = hitpointsSave
    data["hitPoints"] = hitPoints
    data["stageIndex"] = stageIndex
    data["isRemove"] = isRemove
    data["hitpointScale"] = hitpointScale
    data["hitpointScaleSave"] = hitpointScaleSave
    return data

func ImportSave(data: Dictionary) -> void :
    hitpointScaleSave = data.get("hitpointScaleSave", hitpointScaleSave)
    hitpointScale = data.get("hitpointScale", hitpointScale)
    hitpointsSave = data.get("hitpointsSave", hitpointsSave)
    hitPoints = data.get("hitPoints", hitPoints)
    var savedStageIndex: int = data.get("stageIndex", 0)
    if savedStageIndex > stageIndex:
        for i in savedStageIndex - stageIndex:
            stageIndex = stageIndex + 1
            SetDamageStage(stageIndex)
    stageIndex = savedStageIndex

func _init(_character: TowerDefenseCharacter, _slotConfig: ArmorSlotConfig) -> void :
    character = _character
    slotConfig = _slotConfig

    if !slotConfig:
        isRemove = true
        return

    TowerDefenseArmorRegistry.Init()
    typeData = TowerDefenseArmorRegistry.GetArmorType(slotConfig.armorName)
    if typeData == null:
        isRemove = true
        return

    damagePointBase = slotConfig.damagePoint if slotConfig.damagePoint >= 0 else typeData.damagePoint
    hitPoints = damagePointBase
    hitpointsSave = damagePointBase
    armorMethodFlags = typeData.armorMethodFlags

    if armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DAMAGEABLE:
        stagePersontage = typeData.stagePersontage

    match slotConfig.replaceMethod:
        "Media":
            character.SetArmor(slotConfig.armorName, 0)
        "Sprite":
            var slot: AdobeAnimateSlot = character.sprite.get_node(slotConfig.slotPath)
            sprite = Sprite2D.new()

            sprite.texture = typeData.stageAnimeTexture[0]
            sprite.position = slotConfig.offset
            sprite.rotation = slotConfig.rotation
            sprite.scale = slotConfig.scale
            slot.add_child(sprite)

func Hurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true, ignoreLimit: bool = false) -> float:
    num = DealHurt(num, playSplatAudio, velocity, createDamagePart, ignoreLimit)
    return num

func DealHurt(num: float, playSplatAudio: bool = true, velocity: Vector2 = Vector2.ZERO, createDamagePart: bool = true, ignoreLimit: bool = false) -> float:
    if isRemove:
        return num
    if !ignoreLimit && typeData.limitMaxHit != -1.0:
        num = min(num, typeData.limitMaxHit)
    if hitPoints > num:
        character.armorHurt.emit(num)
        hitPoints -= num
        num = 0
    else:
        character.armorHurt.emit(hitPoints)
        num -= hitPoints
        hitPoints = 0
    if typeData.armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.SHIELD:
        if character.damagePartSlot.has(slotConfig.armorName):
            var slot: AdobeAnimateSlot = character.get_node(character.damagePartSlot[slotConfig.armorName]) as AdobeAnimateSlot
            slot.mode = 1
            slot.position += Vector2(randf_range(-2, 2), randf_range(-2, 2))
            slot.get_tree().create_timer(0.025, false).timeout.connect(
                func():
                    if is_instance_valid(slot):
                        slot.mode = 0
            )
    var impactAudio: String = typeData.impactAudio
    if playSplatAudio && impactAudio != "":
        AudioManager.AudioPlay(impactAudio, AudioManagerEnum.TYPE.SFX)
    if hitPoints > 0:
        if armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DAMAGEABLE:
            var persontage: float = hitPoints / (damagePointBase * hitpointScale)
            if stageIndex < stagePersontage.size():
                while persontage <= stagePersontage[stageIndex]:
                    stageIndex += 1
                    SetDamageStage(stageIndex)
                    if stageIndex >= stagePersontage.size():
                        break
    else:
        if createDamagePart && armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.DROPABLE:
            if velocity == Vector2.ZERO:
                velocity = Vector2(randf_range(-100, 100) * randf_range(0.75, 1.25), -300 * randf_range(0.75, 1.25))
            else:
                velocity = Vector2(velocity.x * randf_range(0.75, 1.25), velocity.y * randf_range(0.75, 1.25))
            DamagePartCreate(velocity)
        Remove()
        hitpointsEmpty.emit(self)
    if armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.ABSORBOVERFLOW:
        return 0
    else:
        return num

func IsMetallic() -> bool:
    return armorMethodFlags & TowerDefenseEnum.ARMOR_METHOD_FLAGS.METALLIC

func Remove() -> void :
    var damageAudio: String = typeData.damageAudio
    if damageAudio != "":
        AudioManager.AudioPlay(damageAudio, AudioManagerEnum.TYPE.SFX)
    match slotConfig.replaceMethod:
        "Media":
            character.ClearArmor(slotConfig.armorName)
            if is_instance_valid(character.sprite):
                character.sprite.SetReplace(slotConfig.replaceMediaName, null)
        "Sprite":
            if is_instance_valid(sprite):
                if sprite.get_parent():
                    sprite.get_parent().remove_child(sprite)
                sprite.queue_free()
            sprite = null

func Draw() -> TowerDefenseMagnet:
    if isRemove:
        return null
    var magnet: TowerDefenseMagnet = character.MagnetCreate(self, sprite)
    sprite = null
    Remove()
    isRemove = true
    remove.emit(self)
    return magnet

func DamagePartCreate(velocity: Vector2 = Vector2.ZERO) -> void :
    character.DamagePartCreate(slotConfig.armorName, sprite, velocity)
    sprite = null

func SetDamageStage(index: int) -> void :
    match slotConfig.replaceMethod:
        "Media":
            character.SetArmor(slotConfig.armorName, index)
        "Sprite":
            if sprite:
                sprite.texture = typeData.stageAnimeTexture[index]
    damagePointReach.emit(self, stageIndex)
