@tool
extends EditorPlugin

var character_editor: Control

func _enter_tree() -> void :
    var _deps: Array[GDScript] = [
        load("res://Resource/General/Character/Armor/ArmorSlotConfig.gd"), 
        load("res://Resource/General/Character/Armor/CharacterArmorData.gd"), 
        load("res://Registry/Armor/Data/TowerDefenseArmorTypeData.gd"), 
        load("res://Registry/Armor/TowerDefenseArmorRegistry.gd"), 
        load("res://Resource/TowerDefense/Character/Config/TowerDefenseCharacterConfig.gd"), 
        load("res://Resource/TowerDefense/Character/Config/TowerDefenseZombieConfig.gd"), 
        load("res://Resource/TowerDefense/Character/Config/TowerDefensePlantConfig.gd"), 
        load("res://Resource/TowerDefense/PacketBank/Packet/TowerDefensePacketConfig.gd"), 
    ]
    var script: GDScript = load("res://addons/character_editor/character_editor.gd")
    if not script:
        push_error("[CharacterEditor] Failed to load character_editor.gd")
        return
    character_editor = script.new()
    if not character_editor:
        push_error("[CharacterEditor] Failed to instantiate editor")
        return
    character_editor.editor_plugin = self
    EditorInterface.get_editor_main_screen().add_child(character_editor)
    _make_visible(false)

func _exit_tree() -> void :
    if is_instance_valid(character_editor):
        character_editor.queue_free()

func _has_main_screen() -> bool:
    return true

func _get_plugin_name() -> String:
    return "Character"

func _make_visible(visible: bool) -> void :
    if is_instance_valid(character_editor):
        character_editor.visible = visible
        if visible and character_editor.has_method("_EnsureLoaded"):
            character_editor._EnsureLoaded()
