@tool
extends TowerDefenseZombie

var walkTime: int = 2
var danceTime: int = 3

var jackson: TowerDefenseCharacter
var _pending_jackson_name: String = ""

func DanceEntered() -> void :
    danceTime = 3
    sprite.scale.x = -1.0
    sprite.SetAnimation("ArmRise", true, 0.2)

@warning_ignore("unused_parameter")
func DanceProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !sprite.pause && attackComponent.CanAttack():
        Attack()

func DanceExited() -> void :
    sprite.scale.x = 1.0

func PointEntered() -> void :
    sprite.SetAnimation("PointUp", false, 0.2)
    sprite.AddAnimation("PointDown", 0.75, false, 0.2)

@warning_ignore("unused_parameter")
func PointProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0

func PointExited() -> void :
    pass

func WalkEntered() -> void :
    super.WalkEntered()
    sprite.scale.x = 1.0
    walkTime = 2

func WalkProcessing(delta: float) -> void :
    if is_instance_valid(jackson):
        groundMoveComponent.alive = jackson.groundMoveComponent.alive
    else:
        groundMoveComponent.alive = true
    super.WalkProcessing(delta)

func DieProcessing(delta: float) -> void :
    super.DieProcessing(delta)
    sprite.timeScale = timeScale * 2.0

func AnimeCompleted(clip: String) -> void :
    super.AnimeCompleted(clip)
    match clip:
        "Walk":
            if (TowerDefenseManager.currentControl && !TowerDefenseManager.currentControl.isGameRunning):
                return
            walkTime -= 1
            if ( !die && !nearDie):
                if walkTime <= 0:
                    if !is_instance_valid(jackson) || (is_instance_valid(jackson) && !jackson.groundMoveComponent.alive):
                        state.send_event("ToDance")
            else:
                OutJackson()
                Die()
        "ArmRise":
            sprite.scale.x = - sprite.scale.x
            danceTime -= 1
            if ( !die && !nearDie):
                if danceTime <= 0:
                    if !is_instance_valid(jackson) || (is_instance_valid(jackson) && !jackson.groundMoveComponent.alive):
                        Walk()
            else:
                OutJackson()
                Die()

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    super.Hypnoses(time, canFliter)
    OutJackson()

func OutJackson() -> void :
    if is_instance_valid(jackson):
        if !jackson.instance.hypnoses:
            jackson.RemoveDancer(self)
        jackson = null

func ExportVariantSave() -> Dictionary:
    var data: Dictionary = {}
    if is_instance_valid(jackson):
        data["jacksonNodeName"] = jackson.name
    return data

func ImportVariantSave(data: Dictionary) -> void :
    if data.has("jacksonNodeName"):
        _pending_jackson_name = data["jacksonNodeName"]

func _physics_process(delta: float) -> void :
    super._physics_process(delta)
    if _pending_jackson_name != "":
        var _characterNode = TowerDefenseManager.GetCharacterNode()
        if is_instance_valid(_characterNode):
            var node = _characterNode.get_node_or_null(_pending_jackson_name)
            if is_instance_valid(node):
                jackson = node
        _pending_jackson_name = ""
