@tool
extends TowerDefensePlant

const HYPNO_PATCH_BODY_2 = preload("uid://trisvt6u5l4b")
const HYPNO_PATCH_BODY_3 = preload("uid://byo6orm75quhp")
const HYPNO_PATCH_BODY = preload("uid://btsule42cwjrl")
const HYPNO_PATCH_HEAD_2 = preload("uid://bwfpe1t5e5b75")
const HYPNO_PATCH_HEAD_3 = preload("uid://by6prmaaf1ocu")
const HYPNO_PATCH_HEAD = preload("uid://2hdb3rhrsahj")

var over: bool = false
var eatTime: int = 0
var spawnPacket: TowerDefensePacketConfig
var maxHitpoint: float = -1
var spawnTimer: float = 0

func IdleProcessing(delta: float) -> void :
    super.IdleProcessing(delta)
    if eatTime > 0:
        spawnTimer += delta
        if spawnTimer >= 30:
            if is_instance_valid(spawnPacket):
                sprite.SetAnimation("Spawn", false, 0.2)
                spawnTimer = 0
                var character = spawnPacket.Create(global_position, gridPos, groundHeight)
                characterNode.add_child(character)
                var tween = character.create_tween()
                tween.set_ease(Tween.EASE_OUT)
                tween.set_trans(Tween.TRANS_BACK)
                tween.set_parallel(true)
                tween.tween_property(character.transformPoint, ^"scale", Vector2.ONE, 0.5).from(Vector2.ONE * 0.5)
                if !instance.hypnoses:
                    character.Hypnoses()
                character.global_position.x = global_position.x
                character.sprite.pause = false
                character.hitBox.monitorable = true
                if character is TowerDefenseZombie:
                    await get_tree().physics_frame
                    character.Walk()


func AttackDeal(character: TowerDefenseCharacter, type: String, num: float) -> void :
    super.AttackDeal(character, type, num)
    if instance.sleep:
        return
    if !is_instance_valid(character):
        return
    if type == "Eat":
        character.Hypnoses()
        if instance.hypnoses != character.instance.hypnoses:
            eatTime += 1
            if character.GetTotalHitPoint() > maxHitpoint:
                spawnPacket = character.packet
            match eatTime:
                1:
                    sprite.SetReplace("HypnoPatch_body.png", HYPNO_PATCH_BODY_2)
                    sprite.SetReplace("HypnoPatch_head.png", HYPNO_PATCH_HEAD_2)
                    sprite.SetFliters(["piece1"], false)
                2:
                    sprite.SetReplace("HypnoPatch_body.png", HYPNO_PATCH_BODY_3)
                    sprite.SetReplace("HypnoPatch_head.png", HYPNO_PATCH_HEAD_3)
                    sprite.SetFliters(["piece4_1", "piece4_2"], false)
        if eatTime >= 3:
            Destroy()

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Spawn":
            Idle()

func Cover(character: TowerDefenseCharacter) -> void :
    if character.config.name == "PlantHypnoShroom":
        if character.instance.wakeUp:
            instance.wakeUp = true

func ExportVariantSave() -> Dictionary:
    var data: Dictionary = {
        "over": over, 
        "eatTime": eatTime, 
        "maxHitpoint": maxHitpoint, 
        "spawnTimer": spawnTimer, 
    }
    if is_instance_valid(spawnPacket):
        data["spawnPacketName"] = spawnPacket.saveKey
    return data

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
    eatTime = data.get("eatTime", 0)
    maxHitpoint = data.get("maxHitpoint", -1)
    spawnTimer = data.get("spawnTimer", 0)
    if data.has("spawnPacketName"):
        spawnPacket = TowerDefenseManager.GetPacketConfig(data["spawnPacketName"])
