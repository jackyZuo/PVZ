class_name TowerDefenseBattleFeatureGemMatch extends TowerDefenseBattleFeature

var config: TowerDefenseBattleFeatureGemMatchConfig
var grid: Array[Array] = []
var gemNode: Node2D
var isProcessing: bool = false
var dragStartPos: Vector2i = Vector2i(-1, -1)
var isDragging: bool = false
var dragStartScreenPos: Vector2 = Vector2.ZERO
var comboCount: int = 0


var _holeCount: int = 0
var _fillHolePacket: TowerDefenseInGamePacketShow = null


var _matchLines: Array = []


var _activeTweens: int = 0


var _cellPositions: Array = []
var _cellSize: Vector2 = Vector2.ZERO


enum State{IDLE, SWAPPING, SWAP_BACK, REMOVING, GRAVITY}
var _state: int = State.IDLE
var _stateTimer: float = 0.0
var _swapA: Vector2i = Vector2i(-1, -1)
var _swapB: Vector2i = Vector2i(-1, -1)
var _pendingMatches: Array = []



func Init(_data: Dictionary) -> void :
    super.Init(_data)
    config = TowerDefenseBattleFeatureGemMatchConfig.new()
    config.Init(data)

func Ready() -> void :
    pass

func GameInit() -> void :
    gemNode = Node2D.new()
    control.AddNode(gemNode, 2)
    InitializeBoard()

func GameInitFromProgress() -> void :
    gemNode = Node2D.new()
    control.AddNode(gemNode, 2)
    _CacheCellPositions()
    grid.clear()
    for y in range(config.boardRows):
        var row: Array = []
        for x in range(config.boardCols):
            row.append(null)
        grid.append(row)

func Process(_delta: float) -> void :
    if !TowerDefenseManager.IsGameRunning():
        return
    _UpdateState(_delta)

func GameStart() -> void :
    _LinkExistingPlants()

    _RemoveOldUpgradePackets()
    _InitUpgradePackets()

    _ConnectPlantDestroySignals()

    _AddFillHolePacket()


func _LinkExistingPlants() -> void :
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem == null:
                continue
            if is_instance_valid(gem.character):
                continue
            var mapPos: Vector2i = _BoardToMap(gem.gridPos)
            var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(mapPos)
            if cell != null:
                for character: TowerDefenseCharacter in cell.characterList:
                    if is_instance_valid(character) && character is TowerDefensePlant:
                        gem.character = character
                        if character.packet != null:
                            gem.characterKey = character.packet.saveKey
                        break

func _RemoveOldUpgradePackets() -> void :

    var seedBankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank") as TowerDefenseBattleFeatureSeedBank
    if seedBankFeature == null || seedBankFeature.seedBank == null:
        return
    var seedBank: TowerDefenseInGameSeedBank = seedBankFeature.seedBank

    var upgradeTargets: Dictionary = {}
    for upgradeDict: Dictionary in config.plantUpgradeList:
        var toKey: String = upgradeDict.get("to", "")
        if toKey != "":
            upgradeTargets[toKey] = true

    var toRemove: Array = []
    for packet: TowerDefenseInGamePacketShow in seedBank.packetList:
        if is_instance_valid(packet) && is_instance_valid(packet.config):
            if upgradeTargets.has(packet.config.saveKey) || packet.has_meta("is_fill_hole_packet"):
                toRemove.append(packet)
    for packet: TowerDefenseInGamePacketShow in toRemove:
        var id: int = seedBank.packetList.find(packet)
        if id >= 0:
            seedBank.packetNameSet.erase(packet.config.saveKey)
            seedBank.packetList.remove_at(id)
            seedBank.packetNum -= 1
        packet.queue_free()

func _ConnectPlantDestroySignals() -> void :
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem != null && is_instance_valid(gem.character) && !gem.isHole:
                if !gem.character.destroy.is_connected(_OnPlantDestroyed):
                    gem.character.destroy.connect(_OnPlantDestroyed)

func _AddFillHolePacket() -> void :
    var seedBankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank") as TowerDefenseBattleFeatureSeedBank
    if seedBankFeature == null || seedBankFeature.seedBank == null:
        return

    var packetKey: String = String(config.plantList[0]) if !config.plantList.is_empty() else ""
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(packetKey)
    if packetConfig == null:
        return
    var packet: TowerDefenseInGamePacketShow = seedBankFeature.seedBank.AddPacket(packetConfig, true)
    if packet != null:
        packet.start = false
        packet.coldDownOpen = false
        packet.coldDownTimer = 0.0
        packet.coldDownProgressBar.visible = false
        packet.riseCost = -1
        packet.costMultiple = -1
        packet.baseItemCost = config.fillHoleCost
        packet.itemCost = config.fillHoleCost
        packet.set_meta("is_fill_hole_packet", true)
        packet.set_meta("is_upgrade_packet", true)
        packet.alive = false
        packet.pressed.disconnect(TowerDefenseManager.GetPacketPickControl().PickPacket)
        packet.pressed.connect(_OnFillHolePacketPressed)
        _fillHolePacket = packet

func _UpdateFillHolePacket() -> void :
    if !is_instance_valid(_fillHolePacket):
        return
    if _holeCount > 0:
        _fillHolePacket.alive = true
    else:
        _fillHolePacket.alive = false

func _OnFillHolePacketPressed(_packet: TowerDefenseInGamePacketShow) -> void :
    if _holeCount <= 0:
        return

    if config.fillHoleCost > 0:
        var sunFeature = GetFeature("Sun")
        if sunFeature == null || sunFeature.sunNum < config.fillHoleCost:
            return
        sunFeature.sunNum -= config.fillHoleCost
        sunFeature.sunChange.emit( - config.fillHoleCost)

    var holes: Array = []
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem != null && gem.isHole:
                holes.append(Vector2i(x, y))
    if holes.is_empty():
        return

    var holePos: Vector2i = holes[randi() % holes.size()]
    var oldGem: GemPiece = grid[holePos.y][holePos.x]
    if oldGem != null:
        oldGem.queue_free()
    grid[holePos.y][holePos.x] = null

    var plantKey: StringName = config.plantList[randi() % config.plantList.size()]
    _CreateGemAt(holePos, plantKey)

    var newGem: GemPiece = grid[holePos.y][holePos.x]
    if newGem != null && is_instance_valid(newGem.character):
        if !newGem.character.destroy.is_connected(_OnPlantDestroyed):
            newGem.character.destroy.connect(_OnPlantDestroyed)
    _holeCount -= 1
    _UpdateFillHolePacket()

func _InitUpgradePackets() -> void :

    var added: Dictionary = {}
    for plantKey: StringName in config.plantList:
        var toKey: StringName = config.GetUpgradeTarget(plantKey)
        if toKey != "" && !added.has(toKey):
            added[toKey] = true
            _AddUpgradePacket(toKey)

func Destroy() -> void :
    if is_instance_valid(gemNode):
        gemNode.queue_free()
        gemNode = null





func _UpdateState(delta: float) -> void :
    match _state:
        State.IDLE:
            _HandleInput()
        State.SWAPPING:
            _stateTimer -= delta
            if _stateTimer <= 0.0:
                var matches: Array = FindMatches()
                if matches.is_empty():
                    _SwapInGrid(_swapA, _swapB)
                    _state = State.SWAP_BACK
                    _stateTimer = 0.15
                else:
                    _pendingMatches = matches
                    _state = State.REMOVING
                    _stateTimer = 0.05
        State.SWAP_BACK:
            _stateTimer -= delta
            if _stateTimer <= 0.0:
                _state = State.IDLE
                isProcessing = false
        State.REMOVING:
            _stateTimer -= delta
            if _stateTimer <= 0.0:
                _RemoveMatches(_pendingMatches)
                _pendingMatches = []
                _ApplyGravityAndFill()
                _state = State.GRAVITY
        State.GRAVITY:
            if _activeTweens <= 0:
                _pendingMatches = FindMatches()
                if _pendingMatches.is_empty():
                    if !_CheckPossibleMoves():
                        ShuffleBoard()
                    _state = State.IDLE
                    isProcessing = false
                else:
                    comboCount += 1
                    _state = State.REMOVING
                    _stateTimer = 0.05

func _StartSwap(a: Vector2i, b: Vector2i) -> void :
    isProcessing = true
    comboCount = 0
    _swapA = a
    _swapB = b
    _SwapInGrid(a, b)
    _state = State.SWAPPING
    _stateTimer = 0.15





func InitializeBoard() -> void :
    grid.clear()
    _CacheCellPositions()
    for y in range(config.boardRows):
        var row: Array = []
        for x in range(config.boardCols):
            row.append(null)
        grid.append(row)
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var pos: Vector2i = Vector2i(x, y)
            var plantKey: StringName = _GetNonMatchingPlant(pos)
            _CreateGemAt(pos, plantKey)
    _ResolveInitialMatches()

func _GetNonMatchingPlant(pos: Vector2i) -> StringName:
    var avoidPlants: Dictionary = {}
    var left: StringName = _GetPlantKeyAt(Vector2i(pos.x - 1, pos.y))
    var left2: StringName = _GetPlantKeyAt(Vector2i(pos.x - 2, pos.y))
    if left != "" && left == left2:
        avoidPlants[left] = true
    var up: StringName = _GetPlantKeyAt(Vector2i(pos.x, pos.y - 1))
    var up2: StringName = _GetPlantKeyAt(Vector2i(pos.x, pos.y - 2))
    if up != "" && up == up2:
        avoidPlants[up] = true
    var plantKey: StringName = config.plantList[randi() % config.plantList.size()]
    var attempts: int = 0
    while avoidPlants.has(plantKey) && attempts < 20:
        plantKey = config.plantList[randi() % config.plantList.size()]
        attempts += 1
    return plantKey

func _GetPlantKeyAt(pos: Vector2i) -> StringName:
    if !_IsValidPos(pos):
        return ""
    var gem: GemPiece = grid[pos.y][pos.x]
    if gem == null:
        return ""
    return gem.characterKey

func _ResolveInitialMatches() -> void :
    if config.plantList.size() < 3:
        return
    var matches: Array = FindMatches()
    var safety: int = 0
    while !matches.is_empty() && safety < 50:
        for gem: GemPiece in matches:
            var avoidPlants: Dictionary = {}
            var left: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x - 1, gem.gridPos.y))
            var left2: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x - 2, gem.gridPos.y))
            if left != "" && left == left2:
                avoidPlants[left] = true
            var right: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x + 1, gem.gridPos.y))
            var right2: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x + 2, gem.gridPos.y))
            if right != "" && right == right2:
                avoidPlants[right] = true
            var up: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x, gem.gridPos.y - 1))
            var up2: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x, gem.gridPos.y - 2))
            if up != "" && up == up2:
                avoidPlants[up] = true
            var down: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x, gem.gridPos.y + 1))
            var down2: StringName = _GetPlantKeyAt(Vector2i(gem.gridPos.x, gem.gridPos.y + 2))
            if down != "" && down == down2:
                avoidPlants[down] = true
            var newKey: StringName = config.plantList[randi() % config.plantList.size()]
            var attempts: int = 0
            while avoidPlants.has(newKey) && attempts < 20:
                newKey = config.plantList[randi() % config.plantList.size()]
                attempts += 1
            gem.characterKey = newKey
            if is_instance_valid(gem.character):
                gem.character.Destroy()
            _PlantCharacter(gem)
        matches = FindMatches()
        safety += 1

func _CreateGemAt(pos: Vector2i, characterKey: StringName) -> GemPiece:
    var gem: GemPiece = GemPiece.new()
    gem.Setup(pos, characterKey)
    gemNode.add_child(gem)
    gem.global_position = _GridToWorld(pos)
    grid[pos.y][pos.x] = gem
    _PlantCharacter(gem)

    if is_instance_valid(gem.character) && !gem.character.destroy.is_connected(_OnPlantDestroyed):
        gem.character.destroy.connect(_OnPlantDestroyed)
    return gem

func _PlantCharacter(gem: GemPiece) -> void :
    var mapPos: Vector2i = _BoardToMap(gem.gridPos)
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(mapPos)

    if cell != null:
        for character: TowerDefenseCharacter in cell.characterList:
            if is_instance_valid(character) && character is TowerDefensePlant:
                gem.character = character
                if character.packet != null:
                    gem.characterKey = character.packet.saveKey
                return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(String(gem.characterKey))
    if packetConfig == null:
        return
    gem.character = packetConfig.Plant(mapPos, true, true)





func _HandleInput() -> void :
    if Input.is_action_just_pressed("Press"):
        var gridPos: Vector2i = _ScreenToGrid(_GetMousePosition())
        if _IsValidPos(gridPos):
            var gem: GemPiece = grid[gridPos.y][gridPos.x]
            if gem != null && !gem.isHole:
                dragStartPos = gridPos
                isDragging = true
                dragStartScreenPos = _GetMousePosition()
    if isDragging && Input.is_action_just_released("Press"):
        isDragging = false
        if dragStartPos == Vector2i(-1, -1):
            return
        var releaseScreenPos: Vector2 = _GetMousePosition()
        var diff: Vector2 = releaseScreenPos - dragStartScreenPos
        if diff.length() < 10.0:
            dragStartPos = Vector2i(-1, -1)
            return
        var swapDir: Vector2i = Vector2i.ZERO
        if absf(diff.x) > absf(diff.y):
            swapDir = Vector2i(1 if diff.x > 0 else -1, 0)
        else:
            swapDir = Vector2i(0, 1 if diff.y > 0 else -1)
        var targetPos: Vector2i = dragStartPos + swapDir
        if _IsValidPos(targetPos):
            var targetGem: GemPiece = grid[targetPos.y][targetPos.x]
            if targetGem == null || !targetGem.isHole:
                _StartSwap(dragStartPos, targetPos)
        dragStartPos = Vector2i(-1, -1)

func _GetMousePosition() -> Vector2:
    return Global.get_viewport().get_mouse_position()





func _SwapInGrid(a: Vector2i, b: Vector2i) -> void :
    var gemA: GemPiece = grid[a.y][a.x]
    var gemB: GemPiece = grid[b.y][b.x]
    grid[a.y][a.x] = gemB
    grid[b.y][b.x] = gemA
    if gemA != null:
        gemA.SetGridPos(b)
        _SwapCharacterAnimated(gemA, 0.15)
    if gemB != null:
        gemB.SetGridPos(a)
        _SwapCharacterAnimated(gemB, 0.15)

func _SwapCharacterAnimated(gem: GemPiece, duration: float) -> void :
    if !is_instance_valid(gem.character):
        return
    var newMapPos: Vector2i = _BoardToMap(gem.gridPos)
    var oldMapPos: Vector2i = gem.character.gridPos
    if oldMapPos == newMapPos:
        return
    var oldCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(oldMapPos)
    var newCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(newMapPos)
    if !is_instance_valid(oldCell) || !is_instance_valid(newCell):
        return
    var oldPos: Vector2 = gem.character.global_position
    var oldShadowPos: Vector2 = Vector2.ZERO
    if is_instance_valid(gem.character.shadowComponent):
        oldShadowPos = gem.character.shadowComponent.saveShadowPosition
    oldCell.RemoveCharacter(gem.character)
    newCell.CharacterPlant(gem.character.packet, gem.character, true)
    gem.character.gridPos = newMapPos
    gem.character.global_position = oldPos
    if is_instance_valid(gem.character.shadowComponent):
        gem.character.shadowComponent.saveShadowPosition = oldShadowPos
    var targetPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(newMapPos)
    var tween: Tween = gem.character.create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(gem.character, "global_position", targetPos, duration)
    if is_instance_valid(gem.character.shadowComponent):
        var shadowTarget: Vector2 = oldShadowPos + targetPos - oldPos
        tween.tween_property(gem.character.shadowComponent, "saveShadowPosition", shadowTarget, duration)

func _MoveCharacterInstant(gem: GemPiece) -> void :
    if !is_instance_valid(gem.character):
        return
    var newMapPos: Vector2i = _BoardToMap(gem.gridPos)
    var oldMapPos: Vector2i = gem.character.gridPos
    if oldMapPos == newMapPos:
        return
    var oldCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(oldMapPos)
    var newCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(newMapPos)
    if !is_instance_valid(oldCell) || !is_instance_valid(newCell):
        return
    var oldPos: Vector2 = gem.character.global_position
    var oldShadowPos: Vector2 = Vector2.ZERO
    if is_instance_valid(gem.character.shadowComponent):
        oldShadowPos = gem.character.shadowComponent.saveShadowPosition
    oldCell.RemoveCharacter(gem.character)
    newCell.CharacterPlant(gem.character.packet, gem.character, true)
    gem.character.gridPos = newMapPos
    var targetPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(newMapPos)
    gem.character.global_position = targetPos
    if is_instance_valid(gem.character.shadowComponent):
        gem.character.shadowComponent.saveShadowPosition = oldShadowPos + targetPos - oldPos

func FindMatches() -> Array:

    var matched: Dictionary = {}

    _matchLines.clear()

    for y in range(config.boardRows):
        var x: int = 0
        while x < config.boardCols:
            var gem: GemPiece = grid[y][x]
            if gem == null || gem.isHole:
                x += 1
                continue
            var key: StringName = gem.characterKey
            var count: int = 1
            while x + count < config.boardCols:
                var next: GemPiece = grid[y][x + count]
                if next == null || next.isHole || next.characterKey != key:
                    break
                count += 1
            if count >= 3:
                var line: Array = []
                for dx in range(count):
                    matched[Vector2i(x + dx, y)] = true
                    line.append(Vector2i(x + dx, y))
                _matchLines.append(line)
            x += count

    for x in range(config.boardCols):
        var y: int = 0
        while y < config.boardRows:
            var gem: GemPiece = grid[y][x]
            if gem == null || gem.isHole:
                y += 1
                continue
            var key: StringName = gem.characterKey
            var count: int = 1
            while y + count < config.boardRows:
                var next: GemPiece = grid[y + count][x]
                if next == null || next.isHole || next.characterKey != key:
                    break
                count += 1
            if count >= 3:
                var line: Array = []
                for dy in range(count):
                    matched[Vector2i(x, y + dy)] = true
                    line.append(Vector2i(x, y + dy))
                _matchLines.append(line)
            y += count
    var result: Array = []
    for key in matched.keys():
        var gem: GemPiece = grid[key.y][key.x]
        if gem != null:
            result.append(gem)
    return result

func _IsCrossMatch(pos: Vector2i) -> bool:
    var hMatch: bool = false
    var vMatch: bool = false
    var left: int = 0
    while pos.x - left - 1 >= 0:
        var gem: GemPiece = grid[pos.y][pos.x - left - 1]
        if gem == null || gem.characterKey != _GetPlantKeyAt(pos):
            break
        left += 1
    var right: int = 0
    while pos.x + right + 1 < config.boardCols:
        var gem: GemPiece = grid[pos.y][pos.x + right + 1]
        if gem == null || gem.characterKey != _GetPlantKeyAt(pos):
            break
        right += 1
    if left + right + 1 >= 3:
        hMatch = true
    var up: int = 0
    while pos.y - up - 1 >= 0:
        var gem: GemPiece = grid[pos.y - up - 1][pos.x]
        if gem == null || gem.characterKey != _GetPlantKeyAt(pos):
            break
        up += 1
    var down: int = 0
    while pos.y + down + 1 < config.boardRows:
        var gem: GemPiece = grid[pos.y + down + 1][pos.x]
        if gem == null || gem.characterKey != _GetPlantKeyAt(pos):
            break
        down += 1
    if up + down + 1 >= 3:
        vMatch = true
    return hMatch && vMatch

func _RemoveMatches(matches: Array) -> void :

    var totalSunCount: int = 0
    for line: Array in _matchLines:
        var lineLen: int = line.size()
        totalSunCount += maxi(lineLen - 2, 1)

    totalSunCount += comboCount

    var crossPositions: Dictionary = {}
    for i in range(_matchLines.size()):
        for j in range(i + 1, _matchLines.size()):
            for posA: Vector2i in _matchLines[i]:
                for posB: Vector2i in _matchLines[j]:
                    if posA == posB:
                        crossPositions[posA] = true
    if !crossPositions.is_empty():
        totalSunCount *= 2

    var centerPos: Vector2 = Vector2.ZERO
    for gem: GemPiece in matches:
        centerPos += _GridToWorld(gem.gridPos)
    centerPos /= matches.size()

    for i in range(totalSunCount):
        var pos: Vector2 = centerPos + Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 0.0))
        TowerDefenseManager.SunCreate(
            pos, 
            config.sunPerMatch, 
            TowerDefenseEnum.SUN_MOVING_METHOD.GRAVITY, 
            0.0, 
            Vector2(randf_range(-50.0, 50.0), -300.0), 
            980.0
        )
    for gem: GemPiece in matches:
        if is_instance_valid(gem.character):

            if gem.character.destroy.is_connected(_OnPlantDestroyed):
                gem.character.destroy.disconnect(_OnPlantDestroyed)
            gem.character.Destroy()
        grid[gem.gridPos.y][gem.gridPos.x] = null
        gem.PlayRemoveAnimation()

func _AddUpgradePacket(upgradeKey: StringName, insertIndex: int = -1) -> void :
    var seedBankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank") as TowerDefenseBattleFeatureSeedBank
    if seedBankFeature == null || seedBankFeature.seedBank == null:
        return
    if seedBankFeature.seedBank.HasPacket(String(upgradeKey)):
        return
    if !seedBankFeature.seedBank.CanAddPacket():
        return
    var packetConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(String(upgradeKey))
    if packetConfig == null:
        return
    var fromKey: StringName = config.GetUpgradeSource(upgradeKey)
    var upgradeCost: int = config.GetUpgradeCost(fromKey)
    var packet: TowerDefenseInGamePacketShow = seedBankFeature.seedBank.AddPacket(packetConfig, true)
    if packet != null:

        packet.start = false

        packet.coldDownOpen = false
        packet.coldDownTimer = 0.0
        packet.coldDownProgressBar.visible = false

        packet.riseCost = -1
        packet.costMultiple = -1
        packet.baseItemCost = upgradeCost
        packet.itemCost = upgradeCost

        packet.set_meta("is_upgrade_packet", true)
        packet.alive = true
        packet.pressed.disconnect(TowerDefenseManager.GetPacketPickControl().PickPacket)
        packet.pressed.connect(_OnUpgradePacketPressed.bind(upgradeKey))

        if insertIndex >= 0 && insertIndex < seedBankFeature.seedBank.packetList.size():
            var currentIdx: int = seedBankFeature.seedBank.packetList.find(packet)
            if currentIdx >= 0 && currentIdx != insertIndex:
                seedBankFeature.seedBank.packetList.remove_at(currentIdx)
                seedBankFeature.seedBank.packetList.insert(insertIndex, packet)

                var container: Node = seedBankFeature.seedBank.packetContainer
                container.move_child(packet, insertIndex)

func _OnUpgradePacketPressed(_packet: TowerDefenseInGamePacketShow, upgradeKey: StringName) -> void :
    var fromKey: StringName = config.GetUpgradeSource(upgradeKey)
    if fromKey == "":
        return

    var cost: int = config.GetUpgradeCost(fromKey)
    if cost > 0:
        var sunFeature = GetFeature("Sun")
        if sunFeature == null || sunFeature.sunNum < cost:
            return
        sunFeature.sunNum -= cost
        sunFeature.sunChange.emit( - cost)
    _UpgradeAllPlants(fromKey, upgradeKey)

    for i in range(config.plantList.size()):
        if config.plantList[i] == fromKey:
            config.plantList[i] = upgradeKey
    var seedBankFeature: TowerDefenseBattleFeatureSeedBank = GetFeature("SeedBank") as TowerDefenseBattleFeatureSeedBank
    var insertIndex: int = -1
    if seedBankFeature != null && seedBankFeature.seedBank != null:
        var seedBank: TowerDefenseInGameSeedBank = seedBankFeature.seedBank
        insertIndex = seedBank.packetList.find(_packet)
        if insertIndex >= 0:
            seedBank.packetNameSet.erase(_packet.config.saveKey)
            seedBank.packetList.remove_at(insertIndex)
            seedBank.packetNum -= 1
        _packet.queue_free()

    var nextUpgrade: StringName = config.GetUpgradeTarget(upgradeKey)
    if nextUpgrade != "":
        _AddUpgradePacket(nextUpgrade, insertIndex)

func _UpgradeAllPlants(fromKey: StringName, toKey: StringName) -> void :
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem != null && gem.characterKey == fromKey:
                _ReplaceGemCharacter(gem, toKey)

func _ReplaceGemCharacter(gem: GemPiece, newKey: StringName) -> void :
    var oldCharacter: TowerDefenseCharacter = gem.character
    var mapPos: Vector2i = _BoardToMap(gem.gridPos)
    var cell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(mapPos)
    var newPacketConfig: TowerDefensePacketConfig = TowerDefenseManager.GetPacketConfig(String(newKey))
    if newPacketConfig == null:
        return

    var charcaterName: String = newPacketConfig.characterConfig.name
    var chacraterScene: PackedScene = TowerDefenseManager.GetChacraterScene(charcaterName)
    if chacraterScene == null:
        return
    var newCharacter: TowerDefenseCharacter = chacraterScene.instantiate()
    var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
    var plantPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(mapPos)
    newCharacter.global_position = plantPos
    newCharacter.gridPos = mapPos
    newCharacter.cost = newPacketConfig.characterConfig.cost
    newCharacter.packet = newPacketConfig
    if is_instance_valid(cell):
        newCharacter.groundHeight = cell.GetGroundHeight(0.5)
    newCharacter.z = newCharacter.groundHeight
    characterNode.add_child(newCharacter)
    if is_instance_valid(cell) && is_instance_valid(oldCharacter):

        if oldCharacter.destroy.is_connected(cell.CharacterDestroy):
            oldCharacter.destroy.disconnect(cell.CharacterDestroy)
        if oldCharacter.destroy.is_connected(_OnPlantDestroyed):
            oldCharacter.destroy.disconnect(_OnPlantDestroyed)

        var idx: int = cell.characterList.find(oldCharacter)
        if idx >= 0:
            cell.characterList[idx] = newCharacter
        else:
            cell.characterList.append(newCharacter)

        if cell.characterSlotDictionary.has(oldCharacter):
            cell.characterSlotDictionary[newCharacter] = cell.characterSlotDictionary[oldCharacter]
            cell.characterSlotDictionary.erase(oldCharacter)
        else:
            cell.characterSlotDictionary[newCharacter] = null

        for type: TowerDefenseEnum.PLANTGRIDTYPE in cell.gridType:
            if !cell.slot.has(type):
                continue
            if cell.slot[type] == oldCharacter:
                cell.slot[type] = newCharacter
                break

        if cell.characterSurround == oldCharacter:
            cell.characterSurround = newCharacter

        if !newCharacter.destroy.is_connected(cell.CharacterDestroy):
            newCharacter.destroy.connect(cell.CharacterDestroy)
        if !newCharacter.destroy.is_connected(_OnPlantDestroyed):
            newCharacter.destroy.connect(_OnPlantDestroyed)

        if !newPacketConfig.GetPlantCover().is_empty():
            newCharacter.Cover(oldCharacter)

        oldCharacter.Destroy()
    elif is_instance_valid(oldCharacter):
        oldCharacter.Destroy()
    gem.characterKey = newKey
    gem.character = newCharacter





func _OnTweenCompleted() -> void :
    _activeTweens -= 1

func _CreateFallTween(chara: Node2D, targetPos: Vector2, shadowComp: Node, shadowTarget: Vector2, duration: float) -> void :
    _activeTweens += 1
    var tween: Tween = chara.create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_parallel(true)
    tween.tween_property(chara, "global_position", targetPos, duration)
    if shadowComp != null:
        tween.tween_property(shadowComp, "saveShadowPosition", shadowTarget, duration)
    tween.chain().tween_callback(_OnTweenCompleted)

func _ApplyGravityAndFill() -> void :
    for x in range(config.boardCols):

        var writeY: int = config.boardRows - 1
        for readY in range(config.boardRows - 1, -1, -1):
            var gem: GemPiece = grid[readY][x]
            if gem != null && gem.isHole:

                continue
            if gem != null:
                if readY != writeY:
                    grid[writeY][x] = gem
                    grid[readY][x] = null
                    gem.SetGridPos(Vector2i(x, writeY))
                    _StartFallToNewCell(gem)
                writeY -= 1

        var emptyCount: int = writeY + 1
        var fillIdx: int = 0
        for y in range(writeY, -1, -1):

            var existing: GemPiece = grid[y][x]
            if existing != null && existing.isHole:
                continue
            var plantKey: StringName = config.plantList[randi() % config.plantList.size()]
            var gem: GemPiece = _CreateGemAt(Vector2i(x, y), plantKey)
            if is_instance_valid(gem.character):
                var targetPos: Vector2 = _GridToWorld(Vector2i(x, y))
                var startPos: Vector2 = targetPos + Vector2(0, - (emptyCount - fillIdx + 1) * 100.0)
                var shadowComp: Node = null
                var shadowTargetPos: Vector2 = Vector2.ZERO
                if is_instance_valid(gem.character.shadowComponent):
                    shadowTargetPos = gem.character.shadowComponent.saveShadowPosition
                    shadowComp = gem.character.shadowComponent
                gem.character.global_position = startPos
                if shadowComp != null:
                    shadowComp.saveShadowPosition = shadowTargetPos + startPos - targetPos
                var dist: float = absf(targetPos.y - startPos.y)
                var duration: float = maxf(0.15, sqrt(dist / 400.0) * 0.5)
                _CreateFallTween(gem.character, targetPos, shadowComp, shadowTargetPos, duration)
            fillIdx += 1

func _StartFallToNewCell(gem: GemPiece) -> void :
    if !is_instance_valid(gem.character):
        return
    var newMapPos: Vector2i = _BoardToMap(gem.gridPos)
    var oldMapPos: Vector2i = gem.character.gridPos
    if oldMapPos == newMapPos:
        return
    var oldCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(oldMapPos)
    var newCell: TowerDefenseCellInstance = TowerDefenseManager.GetMapCell(newMapPos)
    if !is_instance_valid(oldCell) || !is_instance_valid(newCell):
        return
    var startPos: Vector2 = gem.character.global_position
    var shadowStartPos: Vector2 = Vector2.ZERO
    var shadowComp: Node = null
    if is_instance_valid(gem.character.shadowComponent):
        shadowStartPos = gem.character.shadowComponent.saveShadowPosition
        shadowComp = gem.character.shadowComponent
    oldCell.RemoveCharacter(gem.character)
    newCell.CharacterPlant(gem.character.packet, gem.character, true)
    gem.character.gridPos = newMapPos
    gem.character.global_position = startPos
    if shadowComp != null:
        shadowComp.saveShadowPosition = shadowStartPos
    var targetPos: Vector2 = TowerDefenseManager.GetMapCellPlantPos(newMapPos)
    var shadowTargetPos: Vector2 = shadowStartPos + targetPos - startPos
    var dist: float = absf(targetPos.y - startPos.y)
    var duration: float = maxf(0.15, sqrt(dist / 400.0) * 0.5)
    _CreateFallTween(gem.character, targetPos, shadowComp, shadowTargetPos, duration)





func _CheckPossibleMoves() -> bool:
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem == null || gem.isHole:
                continue
            if x + 1 < config.boardCols:
                var rightGem: GemPiece = grid[y][x + 1]
                if rightGem != null && !rightGem.isHole && rightGem.characterKey != gem.characterKey:
                    _QuickSwapData(Vector2i(x, y), Vector2i(x + 1, y))
                    if _HasAnyMatch():
                        _QuickSwapData(Vector2i(x, y), Vector2i(x + 1, y))
                        return true
                    _QuickSwapData(Vector2i(x, y), Vector2i(x + 1, y))
            if y + 1 < config.boardRows:
                var downGem: GemPiece = grid[y + 1][x]
                if downGem != null && !downGem.isHole && downGem.characterKey != gem.characterKey:
                    _QuickSwapData(Vector2i(x, y), Vector2i(x, y + 1))
                    if _HasAnyMatch():
                        _QuickSwapData(Vector2i(x, y), Vector2i(x, y + 1))
                        return true
                    _QuickSwapData(Vector2i(x, y), Vector2i(x, y + 1))
    return false

func _QuickSwapData(a: Vector2i, b: Vector2i) -> void :
    var tmp: GemPiece = grid[a.y][a.x]
    grid[a.y][a.x] = grid[b.y][b.x]
    grid[b.y][b.x] = tmp

func _HasAnyMatch() -> bool:
    for y in range(config.boardRows):
        var x: int = 0
        while x < config.boardCols - 2:
            var gem: GemPiece = grid[y][x]
            if gem == null || gem.isHole:
                x += 1
                continue
            var key: StringName = gem.characterKey
            var count: int = 1
            while x + count < config.boardCols:
                var next: GemPiece = grid[y][x + count]
                if next == null || next.isHole || next.characterKey != key:
                    break
                count += 1
            if count >= 3:
                return true
            x += count
    for x in range(config.boardCols):
        var y: int = 0
        while y < config.boardRows - 2:
            var gem: GemPiece = grid[y][x]
            if gem == null || gem.isHole:
                y += 1
                continue
            var key: StringName = gem.characterKey
            var count: int = 1
            while y + count < config.boardRows:
                var next: GemPiece = grid[y + count][x]
                if next == null || next.isHole || next.characterKey != key:
                    break
                count += 1
            if count >= 3:
                return true
            y += count
    return false

func ShuffleBoard(depth: int = 0) -> void :
    if depth > 5:
        return
    var allGems: Array = []
    var holePositions: Array = []
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem != null && gem.isHole:
                holePositions.append(Vector2i(x, y))
                continue
            if gem != null:
                allGems.append(gem)
            grid[y][x] = null
    allGems.shuffle()
    var idx: int = 0
    for y in range(config.boardRows):
        for x in range(config.boardCols):
            if holePositions.has(Vector2i(x, y)):
                grid[y][x] = null
                continue
            if idx < allGems.size():
                var gem: GemPiece = allGems[idx]
                gem.SetGridPos(Vector2i(x, y))
                gem.global_position = _GridToWorld(Vector2i(x, y))
                _MoveCharacterInstant(gem)
                grid[y][x] = gem
                idx += 1

    for holePos: Vector2i in holePositions:
        var holeGem: GemPiece = GemPiece.new()
        holeGem.Setup(holePos, "")
        gemNode.add_child(holeGem)
        holeGem.global_position = _GridToWorld(holePos)
        holeGem.SetAsHole()
        grid[holePos.y][holePos.x] = holeGem
    if FindMatches().is_empty() && !_CheckPossibleMoves():
        ShuffleBoard(depth + 1)





func OnPlantEaten(pos: Vector2i) -> void :
    if !_IsValidPos(pos):
        return
    var gem: GemPiece = grid[pos.y][pos.x]
    if gem == null:
        return

    if is_instance_valid(gem.character):
        if gem.character.destroy.is_connected(_OnPlantDestroyed):
            gem.character.destroy.disconnect(_OnPlantDestroyed)

    gem.SetAsHole()
    _holeCount += 1
    _UpdateFillHolePacket()

func _OnPlantDestroyed(character: TowerDefenseCharacter) -> void :

    for y in range(config.boardRows):
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem != null && gem.character == character:
                gem.SetAsHole()
                _holeCount += 1
                _UpdateFillHolePacket()
                return





func _IsValidPos(pos: Vector2i) -> bool:
    return pos.x >= 0 && pos.x < config.boardCols && pos.y >= 0 && pos.y < config.boardRows

func _GridToWorld(pos: Vector2i) -> Vector2:
    if pos.y >= 0 && pos.y < _cellPositions.size():
        var row: Array = _cellPositions[pos.y]
        if pos.x >= 0 && pos.x < row.size():
            return row[pos.x]
    return TowerDefenseManager.GetMapCellPlantPos(_BoardToMap(pos))

func _CacheCellPositions() -> void :
    _cellPositions.clear()
    for y in range(config.boardRows):
        var row: Array = []
        for x in range(config.boardCols):
            row.append(TowerDefenseManager.GetMapCellPlantPos(_BoardToMap(Vector2i(x, y))))
        _cellPositions.append(row)
    _cellSize = Vector2.ZERO
    if config.boardCols >= 2:
        _cellSize.x = absf(_cellPositions[0][1].x - _cellPositions[0][0].x)
    if config.boardRows >= 2:
        _cellSize.y = absf(_cellPositions[1][0].y - _cellPositions[0][0].y)

func _ScreenToGrid(screenPos: Vector2) -> Vector2i:
    if _cellPositions.is_empty() || _cellSize.x < 1.0:
        return Vector2i(-1, -1)
    var origin: Vector2 = _cellPositions[0][0]
    var gx: int = int(roundf((screenPos.x - origin.x) / _cellSize.x))
    var gy: int = int(roundf((screenPos.y - origin.y) / _cellSize.y))
    if gx < 0 || gx >= config.boardCols || gy < 0 || gy >= config.boardRows:
        return Vector2i(-1, -1)
    var cellPos: Vector2 = _cellPositions[gy][gx]
    if screenPos.distance_to(cellPos) > 60.0:
        return Vector2i(-1, -1)
    return Vector2i(gx, gy)

func _BoardToMap(boardPos: Vector2i) -> Vector2i:
    return boardPos + Vector2i.ONE





func SaveFeature() -> Dictionary:
    var gridData: Array = []
    for y in range(config.boardRows):
        var rowData: Array = []
        for x in range(config.boardCols):
            var gem: GemPiece = grid[y][x]
            if gem != null && gem.isHole:
                rowData.append({"isHole": true})
            elif gem != null:
                rowData.append({"characterKey": String(gem.characterKey)})
            else:
                rowData.append(null)
        gridData.append(rowData)

    var plantListData: Array = []
    for key: StringName in config.plantList:
        plantListData.append(String(key))
    return {"grid": gridData, "plantList": plantListData, "holeCount": _holeCount}

func LoadFeature(_data: Dictionary, _owner: TowerDefenseLevelSaveConfig) -> void :
    if config == null:
        config = TowerDefenseBattleFeatureGemMatchConfig.new()
        config.Init(data)

    var plantListData: Array = _data.get("plantList", [])
    if !plantListData.is_empty():
        config.plantList.clear()
        for p: String in plantListData:
            config.plantList.append(StringName(p))
    var gridData: Array = _data.get("grid", [])
    if gridData.is_empty():
        return

    if gemNode == null:
        gemNode = Node2D.new()
        control.AddNode(gemNode, 2)
    _CacheCellPositions()
    grid.clear()
    for y in range(config.boardRows):
        var row: Array = []
        for x in range(config.boardCols):
            row.append(null)
        grid.append(row)


    _holeCount = 0
    for y in range(gridData.size()):
        var rowData: Array = gridData[y]
        for x in range(rowData.size()):
            var cellData: Dictionary = rowData[x]
            if cellData != null && !cellData.is_empty():
                if cellData.get("isHole", false):
                    var gem: GemPiece = GemPiece.new()
                    gem.Setup(Vector2i(x, y), "")
                    gemNode.add_child(gem)
                    gem.global_position = _GridToWorld(Vector2i(x, y))
                    gem.SetAsHole()
                    grid[y][x] = gem
                    _holeCount += 1
                else:
                    var gem: GemPiece = GemPiece.new()
                    gem.Setup(Vector2i(x, y), StringName(cellData.get("characterKey", "")))
                    gemNode.add_child(gem)
                    gem.global_position = _GridToWorld(Vector2i(x, y))
                    grid[y][x] = gem

func CanLoadProgress() -> bool:
    return true
