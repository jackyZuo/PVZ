class_name TargetSystem extends Node

var _registry: TowerDefenseBattleCharacterRegistry
var _manager: TowerDefenseManager

func _init(registry: TowerDefenseBattleCharacterRegistry, manager: TowerDefenseManager) -> void :
    _registry = registry
    _manager = manager

func GetProjectileHasTarget(projectile: TowerDefenseProjectile, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

    )
    for checkCharacter: TowerDefenseCharacter in characterList:
        if projectile.CanTarget(checkCharacter) && checkCharacter.CanCollision(projectile.config.collisionFlags):
            if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            return true
    return false

func GetProjectileHasTargetFromArray(projectile: TowerDefenseProjectile, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    for checkCharacter: TowerDefenseCharacter in array:
        if projectile.CanTarget(checkCharacter) && checkCharacter.CanCollision(projectile.config.collisionFlags):
            if checkCharacter.instance.invincible:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            return true
    return false

func GetProjectileHasTargetFromArea(projectile: TowerDefenseProjectile, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.instance.invincible:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if projectile.CanTarget(checkCharacter) && checkCharacter.CanCollision(projectile.config.collisionFlags):
                if checkCharacter is TowerDefenseCrater:
                    continue
                if checkCharacter is TowerDefenseItem:
                    continue
                if fliterGraveStone:
                    if checkCharacter is TowerDefenseGravestone:
                        continue

                if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    continue
                return true
    return false

func GetProjectileTarget(projectile: TowerDefenseProjectile, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter) -> bool:
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            if projectile.CanTarget(checkCharacter) && checkCharacter.CanCollision(projectile.config.collisionFlags):
                if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    return false
                return true
            return false
    )
    return characterList

func GetProjectileTargetFromArray(projectile: TowerDefenseProjectile, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList = array.filter(
        func(checkCharacter: TowerDefenseCharacter) -> bool:
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            if projectile.CanTarget(checkCharacter) && checkCharacter.CanCollision(projectile.config.collisionFlags):
                if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    return false
                return true
            return false
    )
    return characterList

func GetProjectileTargetFromArea(projectile: TowerDefenseProjectile, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.instance.invincible:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if projectile.CanTarget(checkCharacter) && projectile.CanCollision(checkCharacter.instance.maskFlags):
                if !checkLine || (checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck):
                    characterList.append(checkCharacter)
    return characterList

func GetCharacterHasTarget(character: TowerDefenseCharacter, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    var characterList = _registry.GetCleanCharacters()
    for checkCharacter: TowerDefenseCharacter in characterList:
        if !is_instance_valid(checkCharacter):
            continue
        if checkCharacter.instance.invincible:
            continue
        if !checkCharacter.instance.canBeCollection:
            continue
        if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if checkLine && !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            return true
    return false

func GetCharacterHasTargetFromArray(character: TowerDefenseCharacter, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    for checkCharacter: TowerDefenseCharacter in array:
        if checkCharacter.instance.invincible:
            continue
        if !checkCharacter.instance.canBeCollection:
            continue
        if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if checkLine && !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                continue
            return true
    return false

func GetCharacterHasTargetFromArea(character: TowerDefenseCharacter, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true) -> bool:
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
                if checkLine && !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    continue
                return true
    return false

func GetCharacterTarget(character: TowerDefenseCharacter, checkLine: bool = false, checkCollision: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if character.CanTarget(checkCharacter):
                if checkCharacter is TowerDefenseCrater:
                    return false
                if checkCharacter is TowerDefenseItem:
                    return false
                if fliterGraveStone:
                    if checkCharacter is TowerDefenseGravestone:
                        return false

                if checkCollision && !character.CanCollision(checkCharacter.instance.maskFlags):
                    return false
                if checkLine && !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    return false
                return true
            return false
    )
    return characterList

func GetCharacterTargetFromArray(character: TowerDefenseCharacter, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList = array.filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
                if checkCharacter is TowerDefenseCrater:
                    return false
                if checkCharacter is TowerDefenseItem:
                    return false
                if fliterGraveStone:
                    if checkCharacter is TowerDefenseGravestone:
                        return false

                if checkLine && !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    return false
                return true
            return false
    )
    return characterList

func GetCharacterTargetFromArrayWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, array: Array, checkLine: bool = false, fliterGraveStone: bool = true) -> Array:
    var characterList = array.filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if character.CanTarget(checkCharacter) && collisionFlags & checkCharacter.instance.maskFlags:
                if checkCharacter is TowerDefenseCrater:
                    return false
                if checkCharacter is TowerDefenseItem:
                    return false
                if fliterGraveStone:
                    if checkCharacter is TowerDefenseGravestone:
                        return false

                if checkLine && !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    return false
                return true
            return false
    )
    return characterList


func GetCharacterTargetFromArea(character: TowerDefenseCharacter, checkArea: Area2D, checkLine: bool = false, fliterGraveStone: bool = true, fliterVase: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:

            if checkCharacter.die || checkCharacter.nearDie:
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
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if !checkLine || (checkLine && ( !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck)):
                characterList.append(checkCharacter)
    return characterList

func GetCharacterLine(line: int, fliterGraveStone: bool = true) -> Array:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                if !checkCharacter.canCheckTarget:
                    return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            return checkCharacter.gridPos.y == line || checkCharacter.targetRegistrationComponent.allLineCheck
    )
    return characterList

func GetCharacterTargetLine(character: TowerDefenseCharacter, fliterGraveStone: bool = true) -> Array:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
                return checkCharacter.gridPos.y == character.gridPos.y || checkCharacter.targetRegistrationComponent.allLineCheck
            return false
    )
    return characterList

func GetCharacterTargetLineWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, fliterGraveStone: bool = true) -> Array:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            if character.CanTarget(checkCharacter) && collisionFlags & checkCharacter.instance.maskFlags:
                return checkCharacter.gridPos.y == character.gridPos.y || checkCharacter.targetRegistrationComponent.allLineCheck
            return false
    )
    return characterList

func GetCharacterTargetLineFromArray(character: TowerDefenseCharacter, array: Array, fliterGraveStone: bool = true) -> Array:
    var characterList = array.filter(
        func(checkCharacter: TowerDefenseCharacter):
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false

            if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
                return checkCharacter.gridPos.y == character.gridPos.y || checkCharacter.targetRegistrationComponent.allLineCheck
            return false
    )
    return characterList

func GetCharacterTargetLineFromArea(character: TowerDefenseCharacter, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.instance.invincible:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if character.CanTarget(checkCharacter) && character.CanCollision(checkCharacter.instance.maskFlags):
                if checkCharacter.gridPos.y == character.gridPos.y || checkCharacter.targetRegistrationComponent.allLineCheck:
                    characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetLineFromAreaWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.instance.invincible:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue

            if character.CanTarget(checkCharacter) && collisionFlags & checkCharacter.instance.maskFlags:
                if checkCharacter.gridPos.y == character.gridPos.y || checkCharacter.targetRegistrationComponent.allLineCheck:
                    characterList.append(checkCharacter)
    return characterList

func GetCharacterTargetFromAreaWithCollisionFlags(character: TowerDefenseCharacter, collisionFlags: int, checkArea: Area2D, fliterGraveStone: bool = true) -> Array:
    var characterList: Array = []
    var areas = _registry.GetOverlappingAreasCached(checkArea)
    for area: Area2D in areas:
        var checkCharacter = area.get_parent()
        if checkCharacter is TowerDefenseCharacter:
            if checkCharacter.instance.invincible:
                continue
            if !checkCharacter.instance.canBeCollection:
                continue
            if checkCharacter.die || checkCharacter.nearDie:
                continue
            if checkCharacter is TowerDefenseCrater:
                continue
            if checkCharacter is TowerDefenseItem:
                continue
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    continue
            if character.CanTarget(checkCharacter) && collisionFlags & checkCharacter.instance.maskFlags:
                characterList.append(checkCharacter)
    return characterList

func GetCharacterColumn(column: int, fliterGraveStone: bool = true) -> Array:
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                if !checkCharacter.canCheckTarget:
                    return false
            if fliterGraveStone:
                if checkCharacter is TowerDefenseGravestone:
                    return false
            return checkCharacter.gridPos.x == column
    )
    return characterList

func GetCharacterTargetNear(character: TowerDefenseCharacter, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTarget(character, checkLine)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return false

                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
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
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return true

                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
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
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return true

                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
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
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return false

                    return abs(a.global_position.x - character.global_position.x) < abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return false

                    return a.global_position.distance_squared_to(character.global_position) < b.global_position.distance_squared_to(character.global_position)
            )
    return characterList

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
                if checkCharacter.die || checkCharacter.nearDie:
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

                if !( !checkLine || (checkLine && ( !character.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck))):
                    continue

                match method:
                    TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
                        if abs(checkCharacter.global_position.x - character.global_position.x) < abs(returnCharacter.global_position.x - character.global_position.x):
                            returnCharacter = checkCharacter
                    TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
                        if checkCharacter.global_position.distance_squared_to(character.global_position) < returnCharacter.global_position.distance_squared_to(character.global_position):
                            returnCharacter = checkCharacter

                break

    return returnCharacter

func GetProjectileTargetNear(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var mapFeature: TowerDefenseBattleFeatureMap = _manager.GetMapFeature()
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter: TowerDefenseCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if !checkCharacter.targetRegistrationComponent.canProjectileCheck:
                return false
            if projectile.CanTarget(checkCharacter):
                if checkCharacter is TowerDefenseCrater:
                    return false
                if checkCharacter is TowerDefenseItem:
                    return false
                if fliterGravestone:
                    if checkCharacter is TowerDefenseGravestone:
                        return false
                if collisionFlags != -1:
                    if !(collisionFlags & checkCharacter.instance.maskFlags):
                        return false
                else:
                    if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                        return false
                if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                    return false
                if checkCharacter.global_position.x > mapFeature.config.edge.z:
                    return false
                return true
            return false
    )
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return false

                    return abs(a.global_position.x - projectile.global_position.x) < abs(b.global_position.x - projectile.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):

                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return false

                    return a.global_position.distance_squared_to(projectile.global_position) < b.global_position.distance_squared_to(projectile.global_position)
            )
    return characterList

func GetProjectileTargetNearProjectile(projectile: TowerDefenseProjectile, collisionFlags: int = -1, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = true) -> Array:
    var mapFeature: TowerDefenseBattleFeatureMap = _manager.GetMapFeature()
    var characterList = _registry.GetCleanCharacters().filter(
        func(checkCharacter):
            if !is_instance_valid(checkCharacter):
                return false
            if checkCharacter.instance.invincible:
                return false
            if !checkCharacter.instance.canBeCollection:
                return false
            if !checkCharacter.targetRegistrationComponent.canProjectileCheck:
                return false
            if checkCharacter.nearDie || checkCharacter.die:
                return false
            if !projectile.CanTarget(checkCharacter):
                return false
            if checkCharacter is TowerDefenseCrater:
                return false
            if checkCharacter is TowerDefenseItem:
                return false
            if fliterGravestone:
                if checkCharacter is TowerDefenseGravestone:
                    return false
            if is_instance_valid(checkCharacter.hitBox) && checkCharacter.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
                return false
            if collisionFlags != -1:
                if !(collisionFlags & checkCharacter.instance.maskFlags):
                    return false
            else:
                if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                    return false
            if checkLine && !projectile.CheckSameLine(checkCharacter.gridPos.y) && !checkCharacter.targetRegistrationComponent.allLineCheck:
                return false
            if checkCharacter.global_position.x > mapFeature.config.edge.z:
                return false
            return true
    )
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return false

                    return abs(a.global_position.x - projectile.global_position.x) < abs(b.global_position.x - projectile.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):

                    if projectile.config.collisionFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE:
                        if !(a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && (b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return false
                        elif (a.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE) && !(b.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
                            return true
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return true
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
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
    for checkCharacter in _registry.GetCleanCharacters():
        if !is_instance_valid(checkCharacter):
            continue
        if checkCharacter.instance.invincible:
            continue
        if !checkCharacter.instance.canBeCollection:
            continue
        if !checkCharacter.targetRegistrationComponent.canProjectileCheck:
            continue
        if checkCharacter.nearDie || checkCharacter.die:
            continue
        if !projectile.CanTarget(checkCharacter):
            continue
        if checkCharacter is TowerDefenseCrater:
            continue
        if checkCharacter is TowerDefenseItem:
            continue
        if fliterGravestone && checkCharacter is TowerDefenseGravestone:
            continue
        if is_instance_valid(checkCharacter.hitBox) && checkCharacter.hitBox.process_mode == ProcessMode.PROCESS_MODE_DISABLED:
            continue
        if collisionFlags != -1:
            if !(collisionFlags & checkCharacter.instance.maskFlags):
                continue
        else:
            if !projectile.CanCollision(checkCharacter.instance.maskFlags):
                continue
        if checkCharacter.global_position.x > edge_z:
            continue
        var dist_sq: float = checkCharacter.global_position.distance_squared_to(projectile_pos)
        if has_off_ground_flag && (checkCharacter.instance.maskFlags & TowerDefenseEnum.CHARACTER_COLLISION_FLAGS.OFF_GROUND_CHARACTRE):
            dist_sq *= 0.5
        if dist_sq < best_distance_sq:
            best_distance_sq = dist_sq
            best_character = checkCharacter
    return best_character

func GetCharacterTargetFarFromArray(character: TowerDefenseCharacter, array: Array, method: TowerDefenseEnum.TARGET_NEAR_METHOD = TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT, checkLine: bool = false, fliterGravestone: bool = false) -> Array:
    var characterList = GetCharacterTargetFromArray(character, array, checkLine, false)
    match method:
        TowerDefenseEnum.TARGET_NEAR_METHOD.DEFAULT:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return true

                    return abs(a.global_position.x - character.global_position.x) > abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
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
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return true

                    return abs(a.global_position.x - character.global_position.x) > abs(b.global_position.x - character.global_position.x)
            )
        TowerDefenseEnum.TARGET_NEAR_METHOD.POSITION:
            characterList.sort_custom(
                func(a: TowerDefenseCharacter, b: TowerDefenseCharacter):
                    if fliterGravestone:
                        if a is TowerDefenseGravestone && b is not TowerDefenseGravestone:
                            return false
                        elif a is not TowerDefenseGravestone && b is TowerDefenseGravestone:
                            return true

                    return a.global_position.distance_squared_to(character.global_position) > b.global_position.distance_squared_to(character.global_position)
            )
    return characterList
