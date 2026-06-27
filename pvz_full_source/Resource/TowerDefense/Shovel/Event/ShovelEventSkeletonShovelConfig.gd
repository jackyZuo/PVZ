
class_name ShovelEventSkeletonShovelConfig extends ShovelEventConfig

const RIVIVE = preload("uid://dbgw1lmiiyypp")

func Execute(character: TowerDefenseCharacter) -> void :
    if Global.isMultiplayerMode and !MultiPlayerManager.isHost:
        return
    if character.cost >= 50:
        var deathList: Array[Dictionary] = []
        for _characterData: Dictionary in TowerDefenseManager.deathList:
            if _characterData.has("Camp") && TowerDefenseEnum.CHARACTER_CAMP.PLANT == _characterData["Camp"]:
                deathList.append(_characterData)
        if deathList.size() <= 0:
            return
        var characterData: Dictionary = deathList.pop_back()
        TowerDefenseManager.deathList.erase(characterData)
        var effect: TowerDefenseEffectSpriteOnce = TowerDefenseManager.CreateEffectSpriteOnce(RIVIVE, characterData["GridPos"])
        effect.global_position = characterData["Pos"]
        var characterNode: Node2D = TowerDefenseManager.GetCharacterNode()
        characterNode.add_child(effect)
        var _packet: TowerDefensePacketConfig = characterData["Packet"]
        var zombie: TowerDefenseCharacter = _packet.Create(characterData["Pos"], characterData["GridPos"], 0.0)
        zombie.invisible = characterData["Invisible"]
        characterNode.add_child(zombie)
        if is_instance_valid(zombie.transformPoint):
            zombie.transformPoint.scale = characterData["Scale"] * Vector2.ONE
        if is_instance_valid(zombie.instance):
            zombie.instance.hitpointScale = characterData["HitpointScale"]
        zombie.Hypnoses()
        if Global.isMultiplayerMode and MultiPlayerManager.isHost:
            var control = TowerDefenseManager.currentControl
            if is_instance_valid(control):
                var _sync_id: int = control._get_next_sync_id()
                control._register_sync_character(_sync_id, character)
                MultiPlayerManager.SendSpawnCharacterAt(_packet.saveKey, characterData["GridPos"].x, characterData["GridPos"].y, _sync_id, characterData["HitpointScale"], characterData["Scale"], true, 0.0, true, characterData["Pos"].x, characterData["Pos"].y, true)
        await (Engine.get_main_loop() as SceneTree).physics_frame
        zombie.Walk()
