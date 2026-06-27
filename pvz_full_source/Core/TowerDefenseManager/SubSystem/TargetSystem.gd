class_name TargetSystem extends Node

var _registry: TowerDefenseBattleCharacterRegistry
var _manager: TowerDefenseManager

func _init(registry: TowerDefenseBattleCharacterRegistry, manager: TowerDefenseManager) -> void :
    _registry = registry
    _manager = manager




func _IsBasicTargetValid(checkCharacter: TowerDefenseCharacter, fliterGraveStone: bool = true) -> bool:
    if checkCharacter.instance.invincible:
        return false
    if !checkCharacter.instance.canBeCollection:
        return false
    if checkCharacter is TowerDefenseCrater:
        return false
    if checkCharacter is TowerDefenseItem:
        if !checkCharacter.canCheckTarget:
            return false
    if fliterGraveStone and checkCharacter is TowerDefenseGravestone:
        return false
    return true


func _IsBasicTargetValidWithCheck(checkCharacter: TowerDefenseCharacter, fliterGraveStone: bool = true) -> bool:
    if !is_instance_valid(checkCharacter):
        return false
    return _IsBasicTargetValid(checkCharacter, fliterGraveStone)


func _IsProjectileTargetValid(checkCharacter: TowerDefenseCharacter, fliterGraveStone: bool = true) -> bool:
    if !_IsBasicTargetValid(checkCharacter, fliterGraveStone):
        return false
    if !checkCharacter.targetRegistrationComponent.canProjectileCheck:
        return false
    if checkCharacter.nearDie or checkCharacter.die:
        return false
    return true


func _IsProjectileTargetValidWithCheck(checkCharacter: TowerDefenseCharacter, fliterGraveStone: bool = true) -> bool:
    if !is_instance_valid(checkCharacter):
        return false
    return _IsProjectileTargetValid(checkCharacter, fliterGraveStone)


func _IsAreaTargetValid(checkCharacter: TowerDefenseCharacter, fliterGraveStone: bool = true) -> bool:
    if checkCharacter.die or checkCharacter.nearDie:
        return false
    return _IsBasicTargetValid(checkCharacter, fliterGraveStone)


func _CalcDistance(character_pos: Vector2, checkCharacter: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD) -> float:
    if method == TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
        return abs(checkCharacter.global_position.x - character_pos.x)
    else:
        return checkCharacter.global_position.distance_squared_to(character_pos)


func _GetIterable(checkLine: bool, line: int) -> Array:
    if checkLine:
        return _registry.GetCharactersForLine(line)
    return _registry.GetCleanCharacters()





func GetProjectileHasTarget(projectile: TowerDefenseProjectile, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    for checkCharacter in _GetIterable(checkLine, projectile.gridPos.y):
        if !_IsProjectileTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if projectile.CanTarget(checkCharacter) and checkCharacter.CanCollision(projectile.config.collisionFlags):
            return true
    return false

func GetProjectileHasTargetFromArray(projectile: TowerDefenseProjectile, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    for checkCharacter in array:
        if !_IsProjectileTargetValid(checkCharacter, fliterGraveStone):
            continue
        if projectile.CanTarget(checkCharacter) and checkCharacter.CanCollision(projectile.config.collisionFlags):
            if checkLine and !projectile.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            return true
    return false

func GetProjectileHasTargetFromArea(projectile: TowerDefenseProjectile, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGraveStone):
                continue
            if projectile.CanTarget(checkCharacter) and checkCharacter.CanCollision(projectile.config.collisionFlags):
                if checkLine and !projectile.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                    continue
                return true
    return false





func GetProjectileTarget(projectile: TowerDefenseProjectile, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in _GetIterable(checkLine, projectile.gridPos.y):
        if !_IsProjectileTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if projectile.CanTarget(checkCharacter) and checkCharacter.CanCollision(projectile.config.collisionFlags):
            characterList.append(checkCharacter)
    return characterList

func GetProjectileTargetFromArray(projectile: TowerDefenseProjectile, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in array:
        if !_IsProjectileTargetValid(checkCharacter, fliterGraveStone):
            continue
        if projectile.CanTarget(checkCharacter) and checkCharacter.CanCollision(projectile.config.collisionFlags):
            if checkLine and !projectile.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            characterList.append(checkCharacter)
    return characterList

func GetProjectileTargetFromArea(projectile: TowerDefenseProjectile, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGraveStone):
                continue
            if projectile.CanTarget(checkCharacter) and projectile.CanCollision(checkCharacter.instance.maskFlags):
                if !checkLine or (checkLine and !projectile.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck):
                    characterList.append(checkCharacter)
    return characterList





func GetCharacterHasTarget(character: TowerDefenseCharacter, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    for checkCharacter in _GetIterable(checkLine, character.gridPos.y):
        if !_IsBasicTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
            return true
    return false

func GetCharacterHasTargetFromArray(character: TowerDefenseCharacter, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
            if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            return true
    return false

func GetCharacterHasTargetFromArea(character: TowerDefenseCharacter, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGraveStone):
                continue
            if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
                if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                    continue
                return true
    return false





func GetCharacterTarget(character: TowerDefenseCharacter, checkLine: bool = false, checkCollision: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in _GetIterable(checkLine, character.gridPos.y):
        if !_IsBasicTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter):
            if checkCollision and !character.CanCollision(checkCharacter.instance.maskFlags):
                continue
            characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetFromArray(character: TowerDefenseCharacter, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
            if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and collisionFlags & checkCharacter.instance.maskFlags:
            if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetFromArea(character: TowerDefenseCharacter, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true, fliterVase: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.die or checkCharacter.nearDie:
                continue
            if !character.CanTarget(checkCharacter):
                continue
            if !character.CanCollision(checkCharacter.instance.maskFlags):
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                if !checkCharacter.canCheck:
                    if fliterVase:
                        continue
                    elif !(checkCharacter is TowerDefenseVase):
                        continue
            if fliterGraveStone and checkCharacter is TowerDefenseGravestone:
                continue
            if !checkLine or (checkLine and ( !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck)):
                characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetFromAreaWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGraveStone):
                continue
            if character.CanTarget(checkCharacter) and collisionFlags & checkCharacter.instance.maskFlags:
                characterList.append(checkCharacter)
    return characterList





func GetCharacterLine(line: int, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in _registry.GetCharactersForLine(line):
        if !_IsBasicTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if checkCharacter is TowerDefenseItem:
            if !checkCharacter.canCheckTarget:
                continue
        characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetLine(character: TowerDefenseCharacter, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in _registry.GetCharactersForLine(character.gridPos.y):
        if !_IsBasicTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
            characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetLineWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in _registry.GetCharactersForLine(character.gridPos.y):
        if !_IsBasicTargetValidWithCheck(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and collisionFlags & checkCharacter.instance.maskFlags:
            characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetLineFromArray(character: TowerDefenseCharacter, array: Array, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGraveStone):
            continue
        if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
            if checkCharacter.gridPos.y == character.gridPos.y or checkCharacter.targetRegistrationComponent.allLineCheck:
                characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetLineFromArea(character: TowerDefenseCharacter, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGraveStone):
                continue
            if character.CanTarget(checkCharacter) and character.CanCollision(checkCharacter.instance.maskFlags):
                if checkCharacter.gridPos.y == character.gridPos.y or checkCharacter.targetRegistrationComponent.allLineCheck:
                    characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetLineFromAreaWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGraveStone):
                continue
            if character.CanTarget(checkCharacter) and collisionFlags & checkCharacter.instance.maskFlags:
                if checkCharacter.gridPos.y == character.gridPos.y or checkCharacter.targetRegistrationComponent.allLineCheck:
                    characterList.append(checkCharacter)
    return characterList

func GetCharacterColumn(column: int, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    for checkCharacter in _registry.GetColumnCharacters(column):
        if !_IsBasicTargetValid(checkCharacter, fliterGraveStone):
            continue
        if checkCharacter is TowerDefenseItem:
            if !checkCharacter.canCheckTarget:
                continue
        characterList.append(checkCharacter)
    return characterList





func GetCharacterTargetNear(character: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTarget(character, checkLine)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return a.global_position.distance_squared_to(character.global_position) < b.global_position.distance_squared_to(character.global_position)
            )
    return characterList

func GetCharacterTargetNearFromArray(character: TowerDefenseCharacter, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTargetFromArray(character, array, checkLine, false)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return a.global_position.distance_squared_to(character.global_position) < b.global_position.distance_squared_to(character.global_position)
            )
    return characterList

func GetCharacterTargetNearFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTargetFromArrayWithCollisionFlags(character, collisionFlags, array, checkLine, false)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return a.global_position.distance_squared_to(character.global_position) < b.global_position.distance_squared_to(character.global_position)
            )
    return characterList

func GetCharacterTargetNearFromArea(character: TowerDefenseCharacter, checkArea: Area2D, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTargetFromArea(character, checkArea, checkLine)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return a.global_position.distance_squared_to(character.global_position) < b.global_position.distance_squared_to(character.global_position)
            )
    return characterList

func GetCharacterTargetFarFromArray(character: TowerDefenseCharacter, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTargetFromArray(character, array, checkLine, false)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return abs(a.global_position.x - character.global_position.x) > abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return a.global_position.distance_squared_to(character.global_position) > b.global_position.distance_squared_to(character.global_position)
            )
    return characterList

func GetCharacterTargetFarFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTargetFromArrayWithCollisionFlags(character, collisionFlags, array, checkLine, false)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return abs(a.global_position.x - character.global_position.x) > abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return true
                    return a.global_position.distance_squared_to(character.global_position) > b.global_position.distance_squared_to(character.global_position)
            )
    return characterList






func GetCharacterTargetNearest(character: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> TowerDefenseCharacter:
    var best: TowerDefenseCharacter = null
    var best_dist: float = INF
    var char_pos: Vector2 = character.global_position
    for checkCharacter in _GetIterable(checkLine, character.gridPos.y):
        if !_IsBasicTargetValidWithCheck(checkCharacter, fliterGravestone):
            continue
        if !character.CanTarget(checkCharacter):
            continue
        if !character.CanCollision(checkCharacter.instance.maskFlags):
            continue
        var dist: float = _CalcDistance(char_pos, checkCharacter, method)
        if fliterGravestone and checkCharacter is TowerDefenseGravestone:
            dist += 1000000.0
        if dist < best_dist:
            best_dist = dist
            best = checkCharacter
    return best


func GetCharacterTargetNearestFromArray(character: TowerDefenseCharacter, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> TowerDefenseCharacter:
    var best: TowerDefenseCharacter = null
    var best_dist: float = INF
    var char_pos: Vector2 = character.global_position
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGravestone):
            continue
        if !character.CanTarget(checkCharacter) or !character.CanCollision(checkCharacter.instance.maskFlags):
            continue
        if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
            continue
        var dist: float = _CalcDistance(char_pos, checkCharacter, method)
        if fliterGravestone and checkCharacter is TowerDefenseGravestone:
            dist += 1000000.0
        if dist < best_dist:
            best_dist = dist
            best = checkCharacter
    return best


func GetCharacterTargetNearestFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> TowerDefenseCharacter:
    var best: TowerDefenseCharacter = null
    var best_dist: float = INF
    var char_pos: Vector2 = character.global_position
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGravestone):
            continue
        if !character.CanTarget(checkCharacter) or !(collisionFlags & checkCharacter.instance.maskFlags):
            continue
        if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
            continue
        var dist: float = _CalcDistance(char_pos, checkCharacter, method)
        if fliterGravestone and checkCharacter is TowerDefenseGravestone:
            dist += 1000000.0
        if dist < best_dist:
            best_dist = dist
            best = checkCharacter
    return best


func GetCharacterTargetFarthestFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> TowerDefenseCharacter:
    var best: TowerDefenseCharacter = null
    var best_dist: float = -1.0
    var char_pos: Vector2 = character.global_position
    for checkCharacter in array:
        if !_IsBasicTargetValid(checkCharacter, fliterGravestone):
            continue
        if !character.CanTarget(checkCharacter) or !(collisionFlags & checkCharacter.instance.maskFlags):
            continue
        if checkLine and !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck:
            continue
        var dist: float = _CalcDistance(char_pos, checkCharacter, method)
        if fliterGravestone and checkCharacter is TowerDefenseGravestone:
            dist -= 1000000.0
        if dist > best_dist:
            best_dist = dist
            best = checkCharacter
    return best


func GetProjectileTargetNearestProjectile(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, fliterGravestone: bool = true) -> TowerDefenseCharacter:
    var mapFeature: TowerDefenseBattleFeatureMap = _manager.GetMapFeature()
    var best: TowerDefenseCharacter = null
    var best_dist: float = INF
    var has_off_ground_flag: bool = projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE
    var projectile_pos: Vector2 = projectile.global_position
    var edge_z: float = mapFeature.config.edge.z
    for checkCharacter in _registry.GetCleanCharacters():
        if !_IsProjectileTargetValidWithCheck(checkCharacter, fliterGravestone):
            continue
        if !projectile.CanTarget(checkCharacter):
            continue
        if !is_instance_valid(checkCharacter.hitBox) or checkCharacter.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            continue
        if collisionFlags != -1:
            if !(collisionFlags & checkCharacter.instance.maskFlags):
                continue
        else:
            if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                continue
        if checkCharacter.global_position.x > edge_z:
            continue
        var dist: float = _CalcDistance(projectile_pos, checkCharacter, method)
        if has_off_ground_flag and (checkCharacter.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
            dist *= 0.5
        if fliterGravestone and checkCharacter is TowerDefenseGravestone:
            dist += 1000000.0
        if dist < best_dist:
            best_dist = dist
            best = checkCharacter
    return best




func GetCharacterTargetNearestFromArea(character: TowerDefenseCharacter, checkArea: Area2D, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, fliterGravestone: bool = false) -> TowerDefenseCharacter:
    var best: TowerDefenseCharacter = null
    var best_dist: float = INF
    var char_pos: Vector2 = character.global_position
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if !_IsAreaTargetValid(checkCharacter, fliterGravestone):
                continue
            if !character.CanTarget(checkCharacter) or !character.CanCollision(checkCharacter.instance.maskFlags):
                continue
            if checkCharacter.gridPos.y != character.gridPos.y and !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            var dist: float = _CalcDistance(char_pos, checkCharacter, method)
            if fliterGravestone and checkCharacter is TowerDefenseGravestone:
                dist += 1000000.0
            if dist < best_dist:
                best_dist = dist
                best = checkCharacter
    return best



func GetNearCharacter(character: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false, fliterVase: bool = true) -> TowerDefenseCharacter:
    var returnCharacter: TowerDefenseCharacter = null
    var space: PhysicsDirectSpaceState2D = _manager.get_world_2d().direct_space_state
    var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, 1)
    var exclude: Array[RID] = []
    ray.collide_with_areas = true
    ray.collide_with_bodies = false
    for i in _manager.gridNum.y:
        exclude = []
        ray.exclude = []
        var line: int = i + 1
        ray.from = _manager.GetMapCellPlantPos(Vector2i(0, line))
        ray.to = Vector2(_manager.GetMapGroundRight(), ray.from.y)
        while (true):
            var collision = space.intersect_ray(ray)
            if collision.is_empty():
                break
            var area = collision["collider"]
            if area is Area2D:
                exclude.append(area.get_rid())
                ray.exclude = exclude
                var checkCharacter: TowerDefenseCharacter = area.get_parent()
                if checkCharacter.die or checkCharacter.nearDie:
                    continue
                if !character.CanTarget(checkCharacter):
                    continue
                if !character.CanCollision(checkCharacter.instance.maskFlags):
                    continue
                if checkCharacter is TowerDefenseCrater:
                    continue
                if checkCharacter is TowerDefenseItem:
                    if !checkCharacter.canCheck:
                        if fliterVase:
                            continue
                        elif !(checkCharacter is TowerDefenseVase):
                            continue
                if fliterGravestone:
                    if checkCharacter is TowerDefenseGravestone:
                        continue
                if !( !checkLine or (checkLine and ( !character.CheckSameLine(checkCharacter.gridPos.y) and !checkCharacter.targetRegistrationComponent.allLineCheck))):
                    continue
                match method:
                    TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
                        if returnCharacter == null or abs(checkCharacter.global_position.x - character.global_position.x) < abs(returnCharacter.global_position.x - character.global_position.x):
                            returnCharacter = checkCharacter
                    TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
                        if returnCharacter == null or checkCharacter.global_position.distance_squared_to(character.global_position) < returnCharacter.global_position.distance_squared_to(character.global_position):
                            returnCharacter = checkCharacter
                break
    return returnCharacter





func GetProjectileTargetNear(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var mapFeature: TowerDefenseBattleFeatureMap = _manager.GetMapFeature()
    var characterList: Array = []
    var edge_z: float = mapFeature.config.edge.z
    for checkCharacter in _GetIterable(checkLine, projectile.gridPos.y):
        if !_IsProjectileTargetValidWithCheck(checkCharacter, fliterGravestone):
            continue
        if !projectile.CanTarget(checkCharacter):
            continue
        if collisionFlags != -1:
            if !(collisionFlags & checkCharacter.instance.maskFlags):
                continue
        else:
            if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                continue
        if checkCharacter.global_position.x > edge_z:
            continue
        characterList.append(checkCharacter)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return abs(a.global_position.x - projectile.global_position.x) < abs(b.global_position.x - projectile.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return a.global_position.distance_squared_to(projectile.global_position) < b.global_position.distance_squared_to(projectile.global_position)
            )
    return characterList

func GetProjectileTargetNearProjectile(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = true) -> Array:
    var mapFeature: TowerDefenseBattleFeatureMap = _manager.GetMapFeature()
    var characterList: Array = []
    var edge_z: float = mapFeature.config.edge.z
    for checkCharacter in _GetIterable(checkLine, projectile.gridPos.y):
        if !_IsProjectileTargetValidWithCheck(checkCharacter, fliterGravestone):
            continue
        if !projectile.CanTarget(checkCharacter):
            continue
        if !is_instance_valid(checkCharacter.hitBox) or checkCharacter.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            continue
        if collisionFlags != -1:
            if !(collisionFlags & checkCharacter.instance.maskFlags):
                continue
        else:
            if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                continue
        if checkCharacter.global_position.x > edge_z:
            continue
        characterList.append(checkCharacter)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return abs(a.global_position.x - projectile.global_position.x) < abs(b.global_position.x - projectile.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) and !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone and b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone and b is TowerDefenseGravestone:
                            return false
                    return a.global_position.distance_squared_to(projectile.global_position) < b.global_position.distance_squared_to(projectile.global_position)
            )
    return characterList

func GetProjectileTargetNearest(projectile: TowerDefenseProjectile, collisionFlags: int = -1, fliterGravestone: bool = true) -> TowerDefenseCharacter:
    var mapFeature: TowerDefenseBattleFeatureMap = _manager.GetMapFeature()
    var best_character: TowerDefenseCharacter = null
    var best_distance_sq: float = INF
    var has_off_ground_flag: bool = projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE
    var projectile_pos: Vector2 = projectile.global_position
    var edge_z: float = mapFeature.config.edge.z


    var proj_grid_pos: Vector2i = projectile.gridPos

    var max_search_range_x: int = mini(20, int(projectile.speed / 100.0) + 5)
    var max_search_range_y: int = 10

    for checkCharacter in _registry.GetCleanCharacters():

        var grid_pos: Vector2i = checkCharacter.gridPos

        if abs(grid_pos.x - proj_grid_pos.x) > max_search_range_x:
            continue

        if abs(grid_pos.y - proj_grid_pos.y) > max_search_range_y:
            continue

        if !is_instance_valid(checkCharacter):
            continue

        if checkCharacter.global_position.x > edge_z:
            continue

        if checkCharacter.nearDie or checkCharacter.die:
            continue
        if !checkCharacter.instance.canBeCollection:
            continue
        if checkCharacter.instance.invincible:
            continue
        if !checkCharacter.targetRegistrationComponent.canProjectileCheck:
            continue
        if !projectile.CanTarget(checkCharacter):
            continue
        if checkCharacter is TowerDefenseCrater:
            continue
        if checkCharacter is TowerDefenseItem:
            continue
        if fliterGravestone and checkCharacter is TowerDefenseGravestone:
            continue
        if !is_instance_valid(checkCharacter.hitBox) or checkCharacter.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            continue

        if collisionFlags != -1:
            if !(collisionFlags & checkCharacter.instance.maskFlags):
                continue
        else:
            if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                continue


        var dist_sq: float = checkCharacter.global_position.distance_squared_to(projectile_pos)

        if has_off_ground_flag and (checkCharacter.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
            dist_sq *= 0.5
        if dist_sq < best_distance_sq:
            best_distance_sq = dist_sq
            best_character = checkCharacter
    return best_character
