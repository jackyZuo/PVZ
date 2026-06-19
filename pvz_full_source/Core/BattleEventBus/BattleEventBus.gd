extends Node

@warning_ignore("unused_signal")
signal characterDestroy(packet: TowerDefensePacketConfig, pos: Vector2, gridPos: Vector2, camp: TowerDefenseEnum.CHARACTER_CAMP, scale: float, hitpointScale: float)
@warning_ignore("unused_signal")
signal characterSpawned(character: TowerDefenseCharacter)
@warning_ignore("unused_signal")
signal characterHurt(character: TowerDefenseCharacter, damage: int, source: Node)

@warning_ignore("unused_signal")
signal coldEffectEmit()
@warning_ignore("unused_signal")
signal blowAllEffectEmit()
@warning_ignore("unused_signal")
signal blowLineEffectEmit(line: int)
@warning_ignore("unused_signal")
signal jalaLineEffectEmit(line: int)
@warning_ignore("unused_signal")
signal jalaRowEffectEmit(row: int)
@warning_ignore("unused_signal")
signal jalaGridEffectEmit(gridPos: Vector2i)

@warning_ignore("unused_signal")
signal gameStarted()
@warning_ignore("unused_signal")
signal gameFailed()
@warning_ignore("unused_signal")
signal gameVictory()
@warning_ignore("unused_signal")
signal gamePaused(paused: bool)
@warning_ignore("unused_signal")
signal waveStarted(waveIndex: int)
@warning_ignore("unused_signal")
signal uiSwitched(shown: bool)

@warning_ignore("unused_signal")
signal characterSkinSwitched(packetSaveKey: String, customKey: String)

@warning_ignore("unused_signal")
signal packetUIFront(open: bool)
@warning_ignore("unused_signal")
signal showPlantHealth(show: bool)
@warning_ignore("unused_signal")
signal showZombieHealth(show: bool)
@warning_ignore("unused_signal")
signal screenTransformChanged()

func _ready() -> void :
    get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void :
    screenTransformChanged.emit()
