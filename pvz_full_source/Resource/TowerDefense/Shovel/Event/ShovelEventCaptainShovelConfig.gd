class_name ShovelEventCaptainShovelConfig extends ShovelEventConfig

func Execute(character: TowerDefenseCharacter) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    var height: float = character.GetGroundHeight(character.global_position.y)
    if character.cost < 500:
        for i in floor(character.cost / 100):
            var heightOffset: float = randf_range(-10, 40)
            var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinSilver")
            projectileData.baseDamage = 100.0
            var projectile = FireComponent.CreateProjectilePositionByData(character, null, height + heightOffset - 20, character.global_position + Vector2(randf_range(-10, 10), -20), Vector2(300.0, 0.0), projectileData, -1, character.camp)
            projectile.gridPos.y = character.gridPos.y
        var spawwLineList: Array[int] = []
        for y in range(character.gridPos.y - 1, character.gridPos.y + 2, 1):
            if y >= 1 && y <= TowerDefenseManager.GetMapGridNum().y:
                spawwLineList.append(y)
            else:
                spawwLineList.append(character.gridPos.y)
        for i in floor(character.cost / 100):
            var posX = character.global_position.x + randf_range(-1.5, 1.5) * TowerDefenseManager.GetMapGridSize().x
            TowerDefenseManager.BungiSpawn("ZombieCrew", Vector2i(TowerDefenseManager.GetMapGridPos(Vector2(posX, 0)).x, spawwLineList.pick_random()), null, true)
    else:
        for i in floor(character.cost / 300):
            var heightOffset: float = randf_range(-10, 40)
            var projectileData: TowerDefenseProjectileCreateData = TowerDefenseProjectileCreateData.new(&"CoinGold")
            projectileData.baseDamage = 500.0
            var projectile = FireComponent.CreateProjectilePositionByData(character, null, height + heightOffset - 20, character.global_position + Vector2(randf_range(-10, 10), -20), Vector2(300.0, 0.0), projectileData, -1, character.camp)
            projectile.gridPos.y = character.gridPos.y
        var spawwLineList: Array[int] = []
        for y in range(character.gridPos.y - 1, character.gridPos.y + 2, 1):
            if y >= 1 && y <= TowerDefenseManager.GetMapGridNum().y:
                spawwLineList.append(y)
            else:
                spawwLineList.append(character.gridPos.y)
        for i in floor(character.cost / 500):
            var posX = character.global_position.x + randf_range(-1.5, 1.5) * TowerDefenseManager.GetMapGridSize().x
            TowerDefenseManager.BungiSpawn("ZombieCaptain", Vector2i(TowerDefenseManager.GetMapGridPos(Vector2(posX, 0)).x, spawwLineList.pick_random()), null, true)
