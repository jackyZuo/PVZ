class_name TowerDefenseLevelGridSpawnConfig extends Resource

@export var packet: String = ""
@export var gridPos: Vector2i
@export var override: TowerDefenseCharacterOverride
@export var spawnEvent: Array[TowerDefenseCharacterEventBase] = []
@export var dieEvent: Array[TowerDefenseCharacterEventBase] = []

func Init(spawnDictionary: Dictionary):
    packet = spawnDictionary.get("Packet", "")
    var gridPosGet = spawnDictionary.get_or_add("GridPos", [0, 0])
    gridPos = Vector2i(gridPosGet[0], gridPosGet[1])
    var spawnEventList: Array = spawnDictionary.get("SpawnEvent", []) as Array
    for eventDictionary: Dictionary in spawnEventList:
        var eventName: String = eventDictionary.get("EventName", "")
        if eventName:
            var eventGet = TowerDefenseCharacterEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventDictionary.get("Value", {})
            eventGet.Init(eventValue)
            spawnEvent.append(eventGet)

    var dieEventList: Array = spawnDictionary.get("DieEvent", []) as Array
    for eventDictionary: Dictionary in dieEventList:
        var eventName: String = eventDictionary.get("EventName", "")
        if eventName:
            var eventGet = TowerDefenseCharacterEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventDictionary.get("Value", {})
            eventGet.Init(eventValue)
            dieEvent.append(eventGet)

    var overrideData = spawnDictionary.get("Override", {}) as Dictionary
    if !overrideData.is_empty():
        override = TowerDefenseCharacterOverride.new()
        override.Init(overrideData)

func Export() -> Dictionary:
    var data: Dictionary = {
        "Packet": packet, 
        "GridPos": [gridPos.x, gridPos.y], 
        "SpawnEvent": [], 
        "DieEvent": [], 
    }
    if is_instance_valid(override):
        data["Override"] = override.Export()
    for event: TowerDefenseCharacterEventBase in spawnEvent:
        data["SpawnEvent"].append(event.Export())
    for event: TowerDefenseCharacterEventBase in dieEvent:
        data["DieEvent"].append(event.Export())
    return data
