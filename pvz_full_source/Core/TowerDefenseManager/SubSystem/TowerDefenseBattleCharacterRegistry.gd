class_name TowerDefenseBattleCharacterRegistry extends Node

var _active_characters: Array[TowerDefenseCharacter] = []
var _clean_characters: Array[TowerDefenseCharacter] = []
var _clean_characters_frame: int = -1
var _area_cache: Dictionary = {}
var _area_cache_frame: int = -1
var _effect_count: int = 0
var _effect_count_frame: int = -1
var _line_characters: Dictionary = {}
var _line_characters_frame: int = -1

func Register(character: TowerDefenseCharacter) -> void :
    _active_characters.append(character)

func Unregister(character: TowerDefenseCharacter) -> void :
    _active_characters.erase(character)
    _clean_characters_frame = -1

func GetActiveCharacters() -> Array[TowerDefenseCharacter]:
    return _active_characters

func GetCleanCharacters() -> Array[TowerDefenseCharacter]:
    var current_frame: int = Engine.get_physics_frames()
    if current_frame != _clean_characters_frame:
        _clean_characters_frame = current_frame
        _clean_characters.clear()
        for character in _active_characters:
            if is_instance_valid(character):
                _clean_characters.append(character)
    return _clean_characters

func GetOverlappingAreasCached(checkArea: Area2D) -> Array:
    var current_frame: int = Engine.get_physics_frames()
    if current_frame != _area_cache_frame:
        _area_cache.clear()
        _area_cache_frame = current_frame
    var area_rid: RID = checkArea.get_rid()
    if _area_cache.has(area_rid):
        return _area_cache[area_rid]
    var areas: Array = checkArea.get_overlapping_areas()
    _area_cache[area_rid] = areas
    return areas

func GetEffectCount() -> int:
    var current_frame: int = Engine.get_physics_frames()
    if current_frame != _effect_count_frame:
        _effect_count_frame = current_frame
        _effect_count = get_tree().get_node_count_in_group("Effect")
    return _effect_count

func GetLineCharacters(line: int) -> Array:
    var current_frame: int = Engine.get_physics_frames()
    if current_frame != _line_characters_frame:
        _line_characters_frame = current_frame
        _line_characters.clear()
        for character in GetCleanCharacters():
            var line_key: int = character.gridPos.y
            if !_line_characters.has(line_key):
                _line_characters[line_key] = []
            _line_characters[line_key].append(character)
    if _line_characters.has(line):
        return _line_characters[line]
    return []

func Clear() -> void :
    _active_characters.clear()
    _clean_characters.clear()
    _area_cache.clear()
    _line_characters.clear()
