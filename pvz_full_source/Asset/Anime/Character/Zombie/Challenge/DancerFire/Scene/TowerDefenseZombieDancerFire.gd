@tool
extends TowerDefenseZombie

var walkTime: int = 4
var danceTime: int = 2

var jackson: TowerDefenseCharacter
var _pending_jackson_name: String = ""

func DanceEntered() -> void :
    danceTime = 2
    sprite.SetAnimation("ArmRise", true, 0.2)

@warning_ignore("unused_parameter")
func DanceProcessing(delta: float) -> void :
    sprite.timeScale = timeScale * 1.0
    if !sprite.pause && attackComponent.CanAttack():
        Attack()

func DanceExited() -> void :
    sprite.scale.x = 1.0

func WalkEntered() -> void :
    super.WalkEntered()
    walkTime = 4

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
