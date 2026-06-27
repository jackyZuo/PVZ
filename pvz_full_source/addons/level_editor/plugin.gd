@tool
extends EditorPlugin

var level_editor: Control

func _enter_tree() -> void :
    var _deps: Array[GDScript] = [
        load("res://Resource/TowerDefense/Level/TowerDefenseLevelBaseConfig.gd"), 
        load("res://Resource/TowerDefense/Level/TowerDefenseLevelConfig.gd"), 
        load("res://Resource/TowerDefense/Level/Sun/TowerDefenseLevelSunManagerConfig.gd"), 
        load("res://Resource/TowerDefense/Level/Fog/TowerDefenseLevelFogManagerConfig.gd"), 
        load("res://Resource/TowerDefense/Level/LookStar/TowerDefenseLevelLookStarManagerConfig.gd"), 
        load("res://Resource/TowerDefense/Level/LookStar/TowerDefenseLevelLookStarCheckConfig.gd"), 
        load("res://Resource/TowerDefense/TowerDefenseEnum.gd"), 
        load("res://Resource/General/GeneralEnum.gd"), 
    ]
    var script: GDScript = load("res://addons/level_editor/level_editor.gd")
    if not script:
        push_error("[LevelEditor] Failed to load level_editor.gd")
        return
    level_editor = script.new()
    if not level_editor:
        push_error("[LevelEditor] Failed to instantiate editor")
        return
    level_editor.editor_plugin = self
    EditorInterface.get_editor_main_screen().add_child(level_editor)
    _make_visible(false)

func _exit_tree() -> void :
    if is_instance_valid(level_editor):
        level_editor.queue_free()

func _has_main_screen() -> bool:
    return true

func _get_plugin_name() -> String:
    return "Level"

func _make_visible(visible: bool) -> void :
    if is_instance_valid(level_editor):
        level_editor.visible = visible
        if visible and level_editor.has_method("_EnsureLoaded"):
            level_editor._EnsureLoaded()
