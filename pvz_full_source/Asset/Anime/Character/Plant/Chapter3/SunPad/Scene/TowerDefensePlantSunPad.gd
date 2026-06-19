@tool
extends TowerDefensePlant
@onready var produceComponent: ProduceComponent = %ProduceComponent
@onready var light: PointLight2D = %Light

@export var allEventList: Array[TowerDefenseCharacterEventBase] = []


@export var produceInterval: float = 25.0:
    set(_produceInterval):
        produceInterval = _produceInterval
        if !is_node_ready():
            await ready
        produceComponent.produceInterval = produceInterval
@export var sunNum: int = 25:
    set(_sunNum):
        sunNum = _sunNum
        if !is_node_ready():
            await ready
        produceComponent.num = sunNum

var coldCheckInterval: int = 2

func _physics_process(delta: float) -> void :
    if Engine.is_editor_hint():
        return
    super._physics_process(delta)
    light.visible = TowerDefenseManager.GetMapIsNight() && GameSaveManager.GetConfigValue("MapEffect")
    if coldCheckInterval > 0:
        coldCheckInterval -= 1
    else:
        TowerDefenseExplode.CreateExplode(global_position, Vector2(0.25, 0.25), allEventList, [], TowerDefenseEnum.CHARACTER_CAMP.ALL, -1)
        coldCheckInterval = 2

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    produceComponent.produceType = "BrainSun" if instance.hypnoses else "Sun"

func ExportVariantSave() -> Dictionary:
    return {
        "produceInterval": produceInterval, 
        "sunNum": sunNum, 
        "coldCheckInterval": coldCheckInterval, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    produceInterval = data.get("produceInterval", 25.0)
    sunNum = data.get("sunNum", 25)
    coldCheckInterval = data.get("coldCheckInterval", 2)
