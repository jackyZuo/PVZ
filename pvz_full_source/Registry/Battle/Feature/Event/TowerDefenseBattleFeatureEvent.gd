class_name TowerDefenseBattleFeatureEvent extends TowerDefenseBattleFeature

var eventInit: Array[TowerDefenseLevelEventBase]
var eventReady: Array[TowerDefenseLevelEventBase]
var eventStart: Array[TowerDefenseLevelEventBase]

var _event_sync_buffer: Dictionary = {}

func Init(_data: Dictionary) -> void :
    super.Init(_data)
    var eventInitList: Array = data.get("EventInit", []) as Array
    for eventInitDictionary: Dictionary in eventInitList:
        var eventName: String = eventInitDictionary.get("EventName", "")
        if eventName:
            var event = TowerDefenseLevelEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventInitDictionary.get("Value", {})
            event.Init(eventValue)
            eventInit.append(event)

    var eventReadyList: Array = data.get("EventReady", []) as Array
    for eventReadyDictionary: Dictionary in eventReadyList:
        var eventName: String = eventReadyDictionary.get("EventName", "")
        if eventName:
            var event = TowerDefenseLevelEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventReadyDictionary.get("Value", {})
            event.Init(eventValue)
            eventReady.append(event)

    var eventStartist: Array = data.get("EventStart", []) as Array
    for eventStartDictionary: Dictionary in eventStartist:
        var eventName: String = eventStartDictionary.get("EventName", "")
        if eventName:
            var event = TowerDefenseLevelEventMathine.EventGet(eventName)
            var eventValue: Dictionary = eventStartDictionary.get("Value", {})
            event.Init(eventValue)
            eventStart.append(event)

func GameInit() -> void :
    if !control.isInit:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        await _wait_and_execute_phase("init")
        return
    await TowerDefenseManager.ExecuteLevelEvent(eventInit)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        _broadcast_event_execute("init", eventInit)

func GameInitFromProgress() -> void :
    pass

func GameReady() -> void :
    if !control.hasProgress:
        if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
            await _wait_and_execute_phase("ready")
            return
        await TowerDefenseManager.ExecuteLevelEvent(eventReady)
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            _broadcast_event_execute("ready", eventReady)

func GameStart() -> void :
    if control.hasProgress:
        return
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        if _event_sync_buffer.has("start"):
            await _execute_events_from_data(_event_sync_buffer["start"])
            _event_sync_buffer.erase("start")
        return
    var _config: TowerDefenseLevelConfig = GetLevelControl().config
    await TowerDefenseManager.ExecuteLevelEvent(eventStart)
    if Global.isMultiplayerMode and MultiPlayerManager.isHost:
        _broadcast_event_execute("start", eventStart)

func _wait_and_execute_phase(phase: String) -> void :
    if _event_sync_buffer.has(phase):
        await _execute_events_from_data(_event_sync_buffer[phase])
        _event_sync_buffer.erase(phase)
        return
    while !_event_sync_buffer.has(phase):
        await control.get_tree().process_frame
    await _execute_events_from_data(_event_sync_buffer[phase])
    _event_sync_buffer.erase(phase)

func _broadcast_event_execute(phase: String, events: Array[TowerDefenseLevelEventBase]) -> void :
    var events_data: Array = []
    for event in events:
        events_data.append(event.Export())
    MultiPlayerManager.SendEventExecute(phase, JSON.stringify(events_data))

func _execute_events_from_data(events_data: Variant) -> void :
    if !(events_data is Array):
        return
    for event_data in events_data:
        if !(event_data is Dictionary):
            continue
        var event_name: String = event_data.get("EventName", "")
        if event_name == "":
            continue
        var event = TowerDefenseLevelEventMathine.EventGet(event_name)
        if !is_instance_valid(event):
            continue
        var event_value: Dictionary = event_data.get("Value", {})
        event.Init(event_value)
        @warning_ignore("redundant_await")
        await event.Execute()

func ApplyRemoteEventExecute(phase: String, events_data: Array) -> void :
    _event_sync_buffer[phase] = events_data

func SyncSerialize() -> Dictionary:
    var _data: Dictionary = {}
    var init_data: Array = []
    for event in eventInit:
        init_data.append(event.Export())
    if init_data.size() > 0:
        _data["init"] = init_data
    var ready_data: Array = []
    for event in eventReady:
        ready_data.append(event.Export())
    if ready_data.size() > 0:
        _data["ready"] = ready_data
    var start_data: Array = []
    for event in eventStart:
        start_data.append(event.Export())
    if start_data.size() > 0:
        _data["start"] = start_data
    return _data

func SyncDeserialize(_data: Dictionary) -> void :
    if MultiPlayerManager.isHost:
        return
    if _data.has("init"):
        _execute_events_from_data(_data["init"])
    if _data.has("ready"):
        _execute_events_from_data(_data["ready"])
    if _data.has("start"):
        _execute_events_from_data(_data["start"])
