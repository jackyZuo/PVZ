@tool
extends TowerDefensePlant

const SHIELD_HP: float = 500.0
const SHIELD_INTERVAL: float = 50.0
const SHIELD_TYPE: StringName = &"PumpLantern"

const SURROUND_OFFSETS: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), 
    Vector2i(-1, 0), Vector2i(1, 0), 
    Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), 
]

@onready var light: PointLight2D = %Light

var _shieldTimer: Timer

var _isFromSave: bool = false

func _ready() -> void :
    super._ready()
    if Engine.is_editor_hint():
        return
    AudioManager.AudioPlay("Plantern", AudioManagerEnum.TYPE.SFX)

    await get_tree().process_frame
    if _isFromSave:

        _ShieldStartTimer()
        return

    _GenerateShields()
    _ShieldStartTimer()

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")


func _ShieldStartTimer() -> void :
    _shieldTimer = Timer.new()
    _shieldTimer.wait_time = SHIELD_INTERVAL
    _shieldTimer.autostart = false
    _shieldTimer.one_shot = false
    _shieldTimer.timeout.connect(_GenerateShields)
    add_child(_shieldTimer)
    _shieldTimer.start()


func _GenerateShields() -> void :
    for offset: Vector2i in SURROUND_OFFSETS:
        var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(gridPos + offset)
        if !is_instance_valid(cell):
            continue
        TowerDefenseItemSheild.CreateOnCellWithHP(cell, SHIELD_TYPE, SHIELD_HP)

func ImportVariantSave(data: Dictionary) -> void :
    _isFromSave = true

func ExportVariantSave() -> Dictionary:
    return {}

func _notification(what: int) -> void :
    if what == NOTIFICATION_PREDELETE:
        if is_instance_valid(_shieldTimer):
            _shieldTimer.queue_free()
