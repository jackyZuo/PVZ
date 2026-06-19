@tool
extends TowerDefensePlant
const POR_TALLNUT_BODY = preload("uid://bs7ofo8ns0gja")
const POR_TALLNUT_CRACKED_1 = preload("uid://co7m11ber6yxy")
const POR_TALLNUT_CRACKED_2 = preload("uid://b0n2gnnrjp7nn")
const POR_TALLNUT_LEFT_1 = preload("uid://gmk2eahfgc02")
const POR_TALLNUT_LEFT_2 = preload("uid://bg8metd818nty")
const POR_TALLNUT_LEFT_3 = preload("uid://dbnfbqj81lk5n")
const POR_TALLNUT_MID_1 = preload("uid://llr1lytnmv6p")
const POR_TALLNUT_MID_2 = preload("uid://dquduwep24k4x")
const POR_TALLNUT_MID_3 = preload("uid://d3r08nkknpepr")
const POR_TALLNUT_RIGHT_1 = preload("uid://c1cblsxkffip8")
const POR_TALLNUT_RIGHT_2 = preload("uid://dajcpk5gab5i8")
const POR_TALLNUT_RIGHT_3 = preload("uid://c3qtg8ng54gxx")

@onready var attackComponent: AttackComponent = %AttackComponent

var open: bool = true

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    add_to_group("PorTallnut")
    open = true

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            sprite.SetReplace("PorTallnut_body.png", POR_TALLNUT_BODY)
            sprite.SetReplace("PorTallnut_left1.png", POR_TALLNUT_LEFT_1)
            sprite.SetReplace("PorTallnut_mid1.png", POR_TALLNUT_MID_1)
            sprite.SetReplace("PorTallnut_right1.png", POR_TALLNUT_RIGHT_1)
        "Damage1":
            sprite.SetReplace("PorTallnut_body.png", POR_TALLNUT_CRACKED_1)
            sprite.SetReplace("PorTallnut_left1.png", POR_TALLNUT_LEFT_2)
            sprite.SetReplace("PorTallnut_mid1.png", POR_TALLNUT_MID_2)
            sprite.SetReplace("PorTallnut_right1.png", POR_TALLNUT_RIGHT_2)
        "Damage2":
            sprite.SetReplace("PorTallnut_body.png", POR_TALLNUT_CRACKED_2)
            sprite.SetReplace("PorTallnut_left1.png", POR_TALLNUT_LEFT_3)
            sprite.SetReplace("PorTallnut_mid1.png", POR_TALLNUT_MID_3)
            sprite.SetReplace("PorTallnut_right1.png", POR_TALLNUT_RIGHT_3)

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if open && get_tree().get_node_count_in_group("PorTallnut") >= 2:
        state.send_event("ToOpen")

func OpenEntered() -> void :
    AudioManager.AudioPlay("Portal", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Open", false, 0.2)

@warning_ignore("unused_parameter")
func OpenProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func OpenExited() -> void :
    pass

func OpenIdleEntered() -> void :
    instance.canBeCollection = false
    sprite.SetAnimation("OpenIdle", true, 0.2)

@warning_ignore("unused_parameter")
func OpenIdleProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !open || get_tree().get_node_count_in_group("PorTallnut") < 2:
        state.send_event("ToClose")

    if is_instance_valid(hitBox):
        if hitBox.has_overlapping_areas():
            for area: Area2D in hitBox.get_overlapping_areas():
                AreaEntered(area)




func OpenIdleExited() -> void :
    instance.canBeCollection = true

func CloseEntered() -> void :
    AudioManager.AudioPlay("Portal", AudioManagerEnum.TYPE.SFX)
    sprite.SetAnimation("Close", true, 0.2)

@warning_ignore("unused_parameter")
func CloseProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func CloseExited() -> void :
    pass

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Open":
            state.send_event("ToOpenIdle")
        "Close":
            Idle()

















func AreaEntered(area: Area2D) -> void :
    var character = area.get_parent()
    if character is TowerDefenseGroundItemBase:
        if character is TowerDefensePlant && !(character is TowerDefensePlantBowlingBase):
            return
        if character is TowerDefenseItem && !(character is TowerDefenseMower):
            return
        if character is TowerDefenseCrater:
            return
        if character is TowerDefenseGravestone:
            return
        if character is TowerDefenseCharacter:
            if character is TowerDefenseZombie:
                if character.instance.zombiePhysique == TowerDefenseEnum.ZOMBIE_PHYSIQUE.BOSS:
                    return
                if character.isChangeLine:
                    var mapGridSize: Vector2 = TowerDefenseManager.GetMapGridSize()
                    if abs(character.global_position.y - global_position.y) > mapGridSize.y * 0.5:
                        return
                elif character.gridPos.y != gridPos.y:
                    return

            if character.global_position.x < global_position.x - 10:
                return
            if !character.instance.canBeCollection:
                return
            if !CanTarget(character):
                return
            var porTallnutList = get_tree().get_nodes_in_group("PorTallnut")
            porTallnutList.erase(self)
            if porTallnutList.size() > 0:
                var porTallnut = porTallnutList.pick_random()
                if character.isChangeLine && is_instance_valid(character.garlicComponent):
                    character.garlicComponent.CancelChangeLine()
                character.shadowComponent.saveShadowPosition.y += porTallnut.global_position.y - character.global_position.y
                character.global_position = porTallnut.global_position - Vector2(11, 0)
                character.gridPos = porTallnut.gridPos
        elif character is TowerDefenseProjectile:
            if character.camp != camp:
                return
            if !instance.hypnoses:
                if character.global_position.x < global_position.x - 10:
                    return
                if character.velocity.x > 0:
                    return
            else:
                if character.global_position.x > global_position.x + 10:
                    return
                if character.velocity.x < 0:
                    return
            var porTallnutList = get_tree().get_nodes_in_group("PorTallnut")
            porTallnutList.erase(self)
            if porTallnutList.size() > 0:
                var porTallnut = porTallnutList.pick_random()
                if !instance.hypnoses:
                    character.global_position = porTallnut.global_position - Vector2(11, 0)
                else:
                    character.global_position = porTallnut.global_position + Vector2(11, 0)
                character.gridPos = porTallnut.gridPos


@warning_ignore("unused_parameter")
func Open(pos: Vector2) -> void :
    open = !open
    if open:
        add_to_group("PorTallnut")
    else:
        remove_from_group("PorTallnut")

func ExportVariantSave() -> Dictionary:
    return {
        "open": open, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    open = data.get("open", true)
