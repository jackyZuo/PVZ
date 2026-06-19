extends Node2D

const EFFECT_DIRT_NAME: Dictionary = {
    GeneralEnum.HOMEWORLD.MORDEN: "DirtSpawnGrass"
}
const SURVIVAL_RESOURCE = preload("res://Asset/Config/Survival/SurvivalResource.json")
@export var SURVIVALS: Dictionary = {}

const LEVEL_RESOURCE = preload("res://Asset/Config/Level/LevelResource.json")
@export var LEVELS: Dictionary = {}

const MAP_RESOURCE = preload("res://Asset/Config/Map/MapResource.json")
@export var MAPS: Dictionary = {}

const BGM_RESOURCE = preload("res://Asset/Config/BGM/BGMResource.json")
@export var BGMS: Dictionary = {}

const PROJECTILE_RESOURCE = preload("res://Asset/Config/Projectile/ProjectileResource.json")
@export var PROJECTILE_CONFIG: Dictionary = {}

const AUDIO_RESOURCE = preload("res://Asset/Config/Audio/AudioResource.json")
@export var AUDIOS: Dictionary = {}

const CHARACTER_RESOURCE: JSON = preload("res://Asset/Config/Character/CharacterResource.json")
@export var CHARCTAER_SPRITE: Dictionary = {}
@export var TOWERDEFENSE_CHARCATERS: Dictionary = {}
@export var TOWERDEFENSE_PACKETS: Dictionary = {}

var _character_sprite_paths: Dictionary = {}
var _character_scene_paths: Dictionary = {}
var _packet_paths: Dictionary = {}
var _packets_loaded: bool = false
var _character_sprites_loaded: bool = false
var _background_thread: Thread = Thread.new()
var _background_loading: bool = false
var _mutex: Mutex = Mutex.new()

const TALK_RESOURCE = preload("res://Asset/Config/Npc/TalkResource.json")
@export var TALKS: Dictionary = {}

const TUTORIAL_RESOURCE = preload("res://Asset/Config/Tutorial/TutorialResource.json")
@export var TUTORIALS: Dictionary = {}

const PACKET_BANK_RESOURCE = preload("res://Asset/Config/PacketBank/PacketBankResource.json")
@export var TOWERDEFENSE_PACKETBANKS: Dictionary = {}

const COLLECTABLE_RESOURCE = preload("res://Asset/Config/Collectable/CollectableResource.json")
@export var COLLECTABLES: Dictionary = {}

const SHOVEL_RESOURCE = preload("res://Asset/Config/Shovel/ShovelResource.json")
@export var SHOVELS: Dictionary = {}

const MOWER_RESOURCE = preload("res://Asset/Config/Mower/MowerResource.json")
@export var MOWERS: Dictionary = {}

const SHOP_RESOURCE = preload("res://Asset/Config/Shop/ShopResource.json")
@export var SHOPS: Dictionary = {}

@export var DAILY_LEVEL_DATA: Dictionary = {}

const DAILY_LEVEL_AWARD = preload("res://Asset/Config/DailyChallenge/DailyChallengeAward.json")

signal loadOver()
signal loadPercentage(persontage: float, _stepName: String)

var thread: Thread = Thread.new()

var stepMax: int = 13
var stepName: String = "LoadMap"
var currentStep: int = 0

func _ready() -> void :


    thread.start(Load)

func Load() -> void :
    currentStep = 0
    stepName = "LOAD_MAP"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for mapName: String in MAP_RESOURCE.data.keys():
        MAPS[mapName] = load(MAP_RESOURCE.data[mapName])


    currentStep = 1
    stepName = "LOAD_BGM"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for BGMName: String in BGM_RESOURCE.data.keys():
        BGMS[BGMName] = load(BGM_RESOURCE.data[BGMName])


    currentStep = 2
    stepName = "LOAD_PROJECTILE"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    TowerDefenseProjectileRegistry.Init()

    for ProjectileName: String in PROJECTILE_RESOURCE.data.keys():
        PROJECTILE_CONFIG[ProjectileName] = load(PROJECTILE_RESOURCE.data[ProjectileName])


    currentStep = 3
    stepName = "LOAD_AUDIO"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for audioName: String in AUDIO_RESOURCE.data.keys():
        AUDIOS[audioName] = load(AUDIO_RESOURCE.data[audioName])


    currentStep = 4
    stepName = "LOAD_CHARACTER"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for characterName: String in CHARACTER_RESOURCE.data.keys():
        var characterData: Dictionary = CHARACTER_RESOURCE.data.get(characterName, {}) as Dictionary
        if !characterData.is_empty():
            _character_sprite_paths[characterName] = characterData.get("Sprite")
            _character_scene_paths[characterName] = characterData.get("Scene")
            var characterPacketData: Dictionary = characterData.get("Packet", {}) as Dictionary
            for packetName: String in characterPacketData.keys():
                _packet_paths[packetName] = characterPacketData.get(packetName)

    currentStep = 5
    stepName = "LOAD_TALK"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for talkName: String in TALK_RESOURCE.data.keys():
        TALKS[talkName] = load(TALK_RESOURCE.data[talkName])


    currentStep = 6
    stepName = "LOAD_TUTORIAL"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for tutorialName: String in TUTORIAL_RESOURCE.data.keys():
        TUTORIALS[tutorialName] = load(TUTORIAL_RESOURCE.data[tutorialName])


    currentStep = 7
    stepName = "LOAD_PACKETBANK"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for packetBankName: String in PACKET_BANK_RESOURCE.data.keys():
        var config: TowerDefensePacketBankData = TowerDefensePacketBankData.new()
        var packetBankData: Dictionary = PACKET_BANK_RESOURCE.data[packetBankName]
        var category: Dictionary = packetBankData["Category"]
        config.category = category.duplicate(true)
        TOWERDEFENSE_PACKETBANKS[packetBankName] = config

    for packetBankName: String in PACKET_BANK_RESOURCE.data.keys():
        var packetBankData: Dictionary = PACKET_BANK_RESOURCE.data[packetBankName]
        var include: Array = packetBankData["Include"]
        var config: TowerDefensePacketBankData = TOWERDEFENSE_PACKETBANKS[packetBankName]
        for includeName: String in include:
            var includeConfig: TowerDefensePacketBankData = TOWERDEFENSE_PACKETBANKS[includeName]
            for categoryName: String in includeConfig.category.keys():
                if config.category.has(categoryName):
                    config.category[categoryName].append_array(includeConfig.category[categoryName])
                else:
                    config.category[categoryName] = includeConfig.category[categoryName].duplicate(true)

    currentStep = 8
    stepName = "LOAD_COLLECTABLE"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for collectableName: String in COLLECTABLE_RESOURCE.data.keys():
        COLLECTABLES[collectableName] = load(COLLECTABLE_RESOURCE.data[collectableName])


    currentStep = 9
    stepName = "LOAD_SHOVEL"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for shovelName: String in SHOVEL_RESOURCE.data.keys():
        SHOVELS[shovelName] = load(SHOVEL_RESOURCE.data[shovelName])


    currentStep = 10
    stepName = "LOAD_MOWER"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for mowerName: String in MOWER_RESOURCE.data.keys():
        MOWERS[mowerName] = load(MOWER_RESOURCE.data[mowerName])


    currentStep = 11
    stepName = "LOAD_SHOP"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    for shopName: String in SHOP_RESOURCE.data.keys():
        SHOPS[shopName] = load(SHOP_RESOURCE.data[shopName])


    currentStep = 12
    stepName = "LOAD_LEVEL"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    TowerDefenseBattleRegistry.Init()
    CommandRegistry.Init()

    for survivalName: String in SURVIVAL_RESOURCE.data.keys():
        SURVIVALS[survivalName] = load(SURVIVAL_RESOURCE.data[survivalName])

    LEVELS = LEVEL_RESOURCE.data.duplicate(true)

    currentStep = 13
    stepName = "LOAD_MOD"
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)

    ModManager.Find()

    currentStep = 14
    stepName = ""
    loadPercentage.emit.call_deferred(float(currentStep) / float(stepMax), stepName)
    loadOver.emit.call_deferred()

    thread.wait_to_finish.call_deferred()
    _background_loading = true
    _background_thread.start(_BackgroundLoadCharacter)

func _BackgroundLoadCharacter() -> void :
    for characterName: String in _character_sprite_paths.keys():
        _mutex.lock()
        var need_load: bool = !CHARCTAER_SPRITE.has(characterName)
        _mutex.unlock()
        if need_load:
            var res = load(_character_sprite_paths[characterName])
            _mutex.lock()
            CHARCTAER_SPRITE[characterName] = res
            _mutex.unlock()
    for characterName: String in _character_scene_paths.keys():
        _mutex.lock()
        var need_load: bool = !TOWERDEFENSE_CHARCATERS.has(characterName)
        _mutex.unlock()
        if need_load:
            var res = load(_character_scene_paths[characterName])
            _mutex.lock()
            TOWERDEFENSE_CHARCATERS[characterName] = res
            _mutex.unlock()
    for packetName: String in _packet_paths.keys():
        _mutex.lock()
        var need_load: bool = !TOWERDEFENSE_PACKETS.has(packetName)
        _mutex.unlock()
        if need_load:
            var res = load(_packet_paths[packetName])
            _mutex.lock()
            TOWERDEFENSE_PACKETS[packetName] = res
            _mutex.unlock()
    _mutex.lock()
    _packets_loaded = true
    _character_sprites_loaded = true
    _background_loading = false
    _mutex.unlock()
    _background_thread.wait_to_finish.call_deferred()

func GetCharacterSprite(characterName: String) -> PackedScene:
    _mutex.lock()
    if !CHARCTAER_SPRITE.has(characterName) && _character_sprite_paths.has(characterName):
        _mutex.unlock()
        var res = load(_character_sprite_paths[characterName])
        _mutex.lock()
        CHARCTAER_SPRITE[characterName] = res
    var result = CHARCTAER_SPRITE.get(characterName)
    _mutex.unlock()
    return result

func GetCharacterScene(characterName: String) -> PackedScene:
    _mutex.lock()
    if !TOWERDEFENSE_CHARCATERS.has(characterName) && _character_scene_paths.has(characterName):
        _mutex.unlock()
        var res = load(_character_scene_paths[characterName])
        _mutex.lock()
        TOWERDEFENSE_CHARCATERS[characterName] = res
    var result = TOWERDEFENSE_CHARCATERS.get(characterName)
    _mutex.unlock()
    return result

func GetPacket(packetName: String):
    _mutex.lock()
    if !TOWERDEFENSE_PACKETS.has(packetName) && _packet_paths.has(packetName):
        _mutex.unlock()
        var res = load(_packet_paths[packetName])
        _mutex.lock()
        TOWERDEFENSE_PACKETS[packetName] = res
    var result = TOWERDEFENSE_PACKETS.get(packetName)
    _mutex.unlock()
    return result

func GetPacketNames() -> Array:
    return _packet_paths.keys()

func GetRandomSpriteName() -> String:
    return _character_sprite_paths.keys().pick_random()

func EnsureAllPacketsLoaded() -> void :
    _mutex.lock()
    if _packets_loaded:
        _mutex.unlock()
        return
    _mutex.unlock()
    for packetName: String in _packet_paths.keys():
        _mutex.lock()
        var need_load: bool = !TOWERDEFENSE_PACKETS.has(packetName)
        _mutex.unlock()
        if need_load:
            var res = load(_packet_paths[packetName])
            _mutex.lock()
            TOWERDEFENSE_PACKETS[packetName] = res
            _mutex.unlock()
    _mutex.lock()
    _packets_loaded = true
    _mutex.unlock()

func EnsureAllCharacterSpritesLoaded() -> void :
    _mutex.lock()
    if _character_sprites_loaded:
        _mutex.unlock()
        return
    _mutex.unlock()
    for spriteName: String in _character_sprite_paths.keys():
        _mutex.lock()
        var need_load: bool = !CHARCTAER_SPRITE.has(spriteName)
        _mutex.unlock()
        if need_load:
            var res = load(_character_sprite_paths[spriteName])
            _mutex.lock()
            CHARCTAER_SPRITE[spriteName] = res
            _mutex.unlock()
    _mutex.lock()
    _character_sprites_loaded = true
    _mutex.unlock()
