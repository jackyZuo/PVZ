@tool
extends TowerDefensePlant

@onready var magnetComponent: MagnetComponent = %MagnetComponent
@onready var explodeComponent: ExplodeComponent = %ExplodeComponent

var drawCharacter: Array = []
var over: bool = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if !TowerDefenseManager.IsGameRunning():
        return
    if !inGame:
        return
    if !componentAlive:
        return
    if componentRunning:
        return
    if !over:
        if sprite.clip != "Explode":
            drawCharacter = await magnetComponent.GetCanArmorDrawCharacterList()
            if drawCharacter.size() > 0:
                state.send_event("ToFire")
                return

func FireEntered() -> void :
    instance.invincible = true
    sprite.SetAnimation("Explode", false, 0.0)
    const offsets: Array[Vector2i] = [
        Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), 
        Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), 
        Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), 
    ]
    var gridNum: Vector2i = TowerDefenseManager.GetMapGridNum()
    for character: TowerDefenseCharacter in drawCharacter:
        if is_instance_valid(character):
            var targetGridPos: Vector2i = gridPos + offsets[randi() % offsets.size()]
            targetGridPos = Vector2i(clampi(targetGridPos.x, 1, gridNum.x), clampi(targetGridPos.y, 1, gridNum.y))
            var targetPos: Vector2 = TowerDefenseManager.GetMapCellPosCenter(targetGridPos)
            character.gridPos = targetGridPos
            var tween: Tween = character.create_tween()
            tween.set_parallel(true)
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_QUART)
            tween.tween_property(character, ^"global_position", targetPos, 0.5)
            tween.tween_property(character, ^"shadowComponent:saveShadowPosition:y", character.shadowComponent.saveShadowPosition.y + targetPos.y - character.global_position.y, 0.5)

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
