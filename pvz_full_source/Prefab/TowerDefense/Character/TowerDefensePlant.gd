@tool
class_name TowerDefensePlant extends TowerDefenseCharacter

var waterInteractionComponent: WaterInteractionComponent
var plantAnimeComponent: PlantAnimeComponent
var puzzleShaderComponent: PuzzleShaderComponent

var targetZombie: TowerDefenseCharacter = null
var zombiePlaceDamage: float = 0.0

@export var plantAnimeClip: String = ""

func ShouldUpdateGridPos() -> bool:
    return false

func _ready() -> void :
    if Engine.is_editor_hint():
        return
    super._ready()
    if is_instance_valid(componentManager):
        waterInteractionComponent = componentManager.GetComponentFromType("WaterInteractionComponent")
        plantAnimeComponent = componentManager.GetComponentFromType("PlantAnimeComponent")
        puzzleShaderComponent = componentManager.GetComponentFromType("PuzzleShaderComponent")
    add_to_group("Plant", true)
    instance.hitpointsEmpty.connect(Destroy)
    puzzleShaderComponent.Init()
    showHealthComponent.alive = GameSaveManager.GetConfigValue("ShowPlantHealth")
    BattleEventBus.showPlantHealth.connect(_on_show_plant_health)
    if config.plantGridType.has(TowerDefenseEnum.PLANTGRIDTYPE.AIR):
        shadowComponent.shadowDisabled = true
        shadowSprite.visible = false
    if config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.SPIKE && !(config.physiqueTypeFlags & TowerDefenseEnum.CHARACTER_PHYSIQUE_TYPE.POT):
        shadowComponent.shadowDisabled = true
        shadowSprite.visible = false

func _exit_tree() -> void :
    if Engine.is_editor_hint():
        return
    if is_instance_valid(BattleEventBus) && BattleEventBus.showPlantHealth.is_connected(_on_show_plant_health):
        BattleEventBus.showPlantHealth.disconnect(_on_show_plant_health)

func _on_show_plant_health(_show: bool) -> void :
    showHealthComponent.alive = _show

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if Engine.is_editor_hint():
        return
    if is_instance_valid(targetZombie):
        global_position = targetZombie.global_position
    if (Engine.get_physics_frames() + randFreshIndex) % FRAME_CHECK_INTERVAL == 0:
        instance.RefreshDamagePoint()

func _on_target_zombie_destroyed() -> void :
    targetZombie = null
    Destroy()

func IdleEntered() -> void :
    super.IdleEntered()
    puzzleShaderComponent.IdleEntered()

func IdleExited() -> void :
    super.IdleExited()
    puzzleShaderComponent.IdleExited()

func PlantEntered() -> void :
    plantAnimeComponent.PlantEntered()

@warning_ignore("unused_parameter")
func PlantProcessing(delta: float) -> void :
    plantAnimeComponent.PlantProcessing(delta)

func PlantExited() -> void :
    plantAnimeComponent.PlantExited()

func AnimeEvent(command: String, argument: Variant) -> void :
    super.AnimeEvent(command, argument)

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    plantAnimeComponent.AnimeCompleted(clip)

func InWater() -> void :
    super.InWater()
    if is_instance_valid(waterInteractionComponent):
        waterInteractionComponent.InWater()

func OutWater() -> void :
    super.OutWater()
    if is_instance_valid(waterInteractionComponent):
        waterInteractionComponent.OutWater()
