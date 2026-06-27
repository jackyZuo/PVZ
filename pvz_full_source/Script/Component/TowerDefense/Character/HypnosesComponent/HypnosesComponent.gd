class_name HypnosesComponent extends ComponentBase

var parent: TowerDefenseCharacter

func GetName() -> String:
    return "HypnosesComponent"

func _ready() -> void :
    parent = get_parent().parent
    if !parent.is_node_ready():
        await parent.ready

func Hypnoses(time: float = -1, canFliter: bool = true) -> void :
    if parent.instance.unUseBuffFlags & TowerDefenseEnum.CHARACTER_BUFF_FLAGS.HYPNOSES:
        return

    if parent is TowerDefensePlant:
        if is_instance_valid(parent.cell) && is_instance_valid(parent.cell.itemShield):
            if parent.cell.itemShield.ShieldBlockCharm():
                return
    AudioManager.AudioPlay("Floop", AudioManagerEnum.TYPE.SFX)
    var buffHypnoses: TowerDefenseCharacterBuffHypnoses = TowerDefenseCharacterBuffHypnoses.new()
    buffHypnoses.time = time
    buffHypnoses.canFliter = canFliter
    parent.BuffAdd(buffHypnoses)
