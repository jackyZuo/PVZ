class_name DamagePartComponent extends ComponentBase

var parent: TowerDefenseCharacter

var _sync_part_velocity: Vector2 = Vector2.ZERO
var _sync_deserializing: bool = false

func GetName() -> String:
    return "DamagePartComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func DamagePartCreate(damagePointName: StringName, node: Node2D, velocity: Vector2 = Vector2(randf_range(-100, 100), -300), keepSlotScale: bool = true, offset: Vector2 = Vector2.ZERO, from_sync: bool = false) -> void :
    if !parent.damagePartList.has(damagePointName) or !parent.damagePartSlot.has(damagePointName):
        if !parent.damagePart.has(damagePointName):
            return
        if _try_armor_damage_part(damagePointName, node, velocity, from_sync):
            return
        return
    if _sync_deserializing and _sync_part_velocity != Vector2.ZERO:
        velocity = _sync_part_velocity
        _sync_part_velocity = Vector2.ZERO
        _sync_deserializing = false
    else:
        _sync_part_velocity = velocity
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and !from_sync:
        return
    var slot: AdobeAnimateSlot = parent.get_node(parent.damagePartSlot[damagePointName]) as AdobeAnimateSlot
    if !slot:
        return
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and !from_sync:
        MultiPlayerManager.SendDamagePart(parent.sync_id, String(damagePointName), slot.global_position.x, slot.global_position.y, velocity.x, velocity.y)
    _create_damage_part(damagePointName, node, velocity, keepSlotScale, offset, slot)

func _try_armor_damage_part(damagePointName: StringName, node: Node2D, velocity: Vector2, from_sync: bool) -> bool:
    var damageData = parent.damagePart[damagePointName]
    if !(damageData is ArmorSlotConfig):
        return false
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost and !from_sync:
        return true
    var armorInstance: TowerDefenseArmorInstance = parent.GetArmorFromName(String(damagePointName))
    if !armorInstance or !is_instance_valid(armorInstance):
        return false
    if armorInstance.isRemove and !from_sync:
        return false
    var armor_sprite: Sprite2D = armorInstance.sprite
    if !armor_sprite:
        if armorInstance.slotConfig.replaceMethod == "Sprite" and armorInstance.typeData.stageAnimeTexture.size() > 0:
            armor_sprite = Sprite2D.new()
            armor_sprite.texture = armorInstance.typeData.stageAnimeTexture[mini(armorInstance.stageIndex, armorInstance.typeData.stageAnimeTexture.size() - 1)]
            armor_sprite.position = armorInstance.slotConfig.offset
            armor_sprite.rotation = armorInstance.slotConfig.rotation
            armor_sprite.scale = armorInstance.slotConfig.scale
        else:
            return false
    var send_pos: Vector2 = armor_sprite.global_position if is_instance_valid(armor_sprite) and armor_sprite.is_inside_tree() else parent.global_position
    if Global.isMultiplayerMode and MultiPlayerManager.isHost and !from_sync:
        MultiPlayerManager.SendDamagePart(parent.sync_id, String(damagePointName), send_pos.x, send_pos.y, velocity.x, velocity.y)
    var charcaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var damagePartInstance: DamagePartDrop = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.DAMAGEPART, charcaterNode) as DamagePartDrop
    var part_node: Node2D = null
    if node and is_instance_valid(node):
        if node.get_parent():
            part_node = node.duplicate()
        else:
            part_node = node
    else:
        part_node = armor_sprite.duplicate()
    if part_node:
        damagePartInstance.Init(part_node, parent.GetGroundHeight(send_pos.y) - parent.groundHeight + parent.shadowSprite.position.y + 24, velocity)
        damagePartInstance.scale *= parent.scale * parent.transformPoint.scale * parent.sprite.scale
        damagePartInstance.global_position = send_pos
        damagePartInstance.gridPos = parent.gridPos
        armorInstance.damagePartDropped = true
    return true

func _create_damage_part(damagePointName: StringName, node: Node2D, velocity: Vector2, keepSlotScale: bool, offset: Vector2, slot: AdobeAnimateSlot) -> void :
    var charcaterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var damagePartInstance: DamagePartDrop = ObjectManager.PoolPop(ObjectManagerConfig.OBJECT.DAMAGEPART, charcaterNode) as DamagePartDrop
    if !node:
        var damageData = parent.damagePart[damagePointName]
        if damageData is CharacterDamagePointConfig:
            node = slot.CreatePart(parent.damagePart[damagePointName].animeFliterClose.split("&", false))
        if damageData is ArmorSlotConfig:
            node = slot.CreatePart(damageData.destroyFliter.split("&", false))
            if !node:
                var _armorInstance: TowerDefenseArmorInstance = parent.GetArmorFromName(String(damagePointName))
                if _armorInstance and is_instance_valid(_armorInstance) and _armorInstance.sprite:
                    node = _armorInstance.sprite.duplicate()
    else:
        if node.get_parent():
            node.get_parent().remove_child(node)
            node.position = offset
            if keepSlotScale:
                damagePartInstance.scale = slot.scale
    if !node:
        damagePartInstance.Over()
        return
    damagePartInstance.Init(node, parent.GetGroundHeight(slot.global_position.y) - parent.groundHeight + parent.shadowSprite.position.y, velocity)
    damagePartInstance.scale *= parent.scale * parent.transformPoint.scale * parent.sprite.scale
    damagePartInstance.global_position = slot.global_position
    damagePartInstance.gridPos = parent.gridPos
    var armorInstance: TowerDefenseArmorInstance = parent.GetArmorFromName(String(damagePointName))
    if armorInstance and is_instance_valid(armorInstance):
        armorInstance.damagePartDropped = true

func MagnetCreate(armorInstance: TowerDefenseArmorInstance, node: Node2D) -> TowerDefenseMagnet:
    var damagePointName: String = armorInstance.slotConfig.armorName
    var slot: AdobeAnimateSlot = parent.get_node(parent.damagePartSlot[damagePointName]) as AdobeAnimateSlot
    if !slot:
        return
    var magnetInstance: TowerDefenseMagnet = TowerDefenseMagnet.Create(armorInstance)
    TowerDefenseGroundItemBase.characterNode.add_child(magnetInstance)
    if !node:
        var damageData = parent.damagePart[damagePointName]
        if damageData is CharacterDamagePointConfig:
            node = slot.CreatePart(parent.damagePart[damagePointName].animeFliterClose.split("&", false))
        if damageData is ArmorSlotConfig:
            node = slot.CreatePart(damageData.destroyFliter.split("&", false))
    else:
        if node.get_parent():
            var saveNodeScale: Vector2 = node.global_scale
            node.get_parent().remove_child(node)
            node.scale = saveNodeScale
    magnetInstance.Init(node)
    magnetInstance.global_position = slot.global_position
    node.rotation = slot.rotation
    magnetInstance.gridPos = parent.gridPos
    return magnetInstance

func ArmorDraw(armor: TowerDefenseArmorInstance) -> TowerDefenseMagnet:
    return parent.instance.ArmorDraw(armor)

func SyncSerialize() -> Dictionary:
    var data: Dictionary = {}
    if _sync_part_velocity != Vector2.ZERO:
        data["part_velocity_x"] = _sync_part_velocity.x
        data["part_velocity_y"] = _sync_part_velocity.y
    return data

func SyncDeserialize(_data: Dictionary) -> void :
    if _data.has("part_velocity_x"):
        _sync_part_velocity = Vector2(_data.get("part_velocity_x", 0.0), _data.get("part_velocity_y", 0.0))
        _sync_deserializing = true
