@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var magnetComponent: MagnetComponent = %MagnetComponent
@onready var potatoComponent: PotatoComponent = %PotatoComponent
@export var readyTime: float = 5.0:
    set(_readyTime):
        readyTime = _readyTime
        if !is_node_ready():
            await ready
        potatoComponent.readyTime = readyTime

var drawCharacter: Array = []

var over: bool = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if potatoComponent.isCharge:
        if sprite.clip != "Fire":
            drawCharacter = await magnetComponent.GetCanArmorDrawCharacterList()
            if drawCharacter.size() > 0:
                state.send_event("ToFire")
                return

func FireEntered() -> void :
    instance.invincible = true
    sprite.SetAnimation("Fire", false, 0.0)
    potatoComponent.process_mode = Node.PROCESS_MODE_DISABLED
    for character: TowerDefenseCharacter in drawCharacter:
        if is_instance_valid(character):
            character.gridPos.y = gridPos.y
            var tween = character.create_tween()
            tween.set_parallel(true)
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_QUART)
            tween.tween_property(character, ^"global_position", global_position, 0.5)
            tween.tween_property(character, ^"shadowComponent:saveShadowPosition:y", character.shadowComponent.saveShadowPosition.y + global_position.y - character.global_position.y, 0.5)

@warning_ignore("unused_parameter")
func FireProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 2.0

func FireExited() -> void :
    pass

func ReadyRise() -> void :
    potatoComponent.ReadyRise()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Fire":
            if over:
                return
            over = true
            potatoComponent.Explode()
            Destroy()

func ExportVariantSave() -> Dictionary:
    return {
        "readyTime": readyTime, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    readyTime = data.get("readyTime", 5.0)
    over = data.get("over", false)
