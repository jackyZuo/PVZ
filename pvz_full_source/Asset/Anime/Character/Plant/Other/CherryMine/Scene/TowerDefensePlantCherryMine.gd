@tool
extends TowerDefensePlant

@onready var attackComponent: AttackComponent = %AttackComponent
@onready var potatoComponent: PotatoComponent = %PotatoComponent
@export var readyTime: float = 15.0:
    set(_readyTime):
        readyTime = _readyTime
        if !is_node_ready():
            await ready
        potatoComponent.readyTime = readyTime

@export var eventlist: Array[TowerDefenseCharacterEventBase] = []

var over: bool = false
var riseDisabled: bool = false

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if potatoComponent.rise and not riseDisabled:
        riseDisabled = true
        potatoComponent.process_mode = Node.PROCESS_MODE_DISABLED
    if potatoComponent.isCharge:
        if sprite.clip != "Fire":
            if attackComponent.CanAttack():
                state.send_event("ToFire")
                return

func FireEntered() -> void :
    instance.invincible = true
    sprite.SetAnimation("Fire", false, 0.0)
    potatoComponent.process_mode = Node.PROCESS_MODE_DISABLED
    TowerDefenseExplode.CreateExplode(global_position, Vector2(1.5, 1.5), eventlist, [], camp, -1)
    await get_tree().create_timer(0.75).timeout
    potatoComponent.Explode()

func FireProcessing(_delta: float) -> void :
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
            Destroy()

func Explode() -> void :
    pass

func ExportVariantSave() -> Dictionary:
    return {
        "readyTime": readyTime, 
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    readyTime = data.get("readyTime", 15.0)
    over = data.get("over", false)
