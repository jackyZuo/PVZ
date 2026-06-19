@tool
extends TowerDefenseZombieGargantuarBase

const ZOMBIE_FOOTBALL_GARGANTUAR_BODY_1 = preload("uid://dwldi31pa311y")
const ZOMBIE_FOOTBALL_GARGANTUAR_BODY_1_2 = preload("uid://cho4e0w7335lx")
const ZOMBIE_FOOTBALL_GARGANTUAR_BODY_1_3 = preload("uid://rm3iebyhewoi")
const ZOMBIE_FOOTBALL_GARGANTUAR_HEAD_2 = preload("uid://d2h300mowbih5")
const ZOMBIE_FOOTBALL_GARGANTUAR_HEAD = preload("uid://ni8doj1carv8")

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            sprite.SetReplace("Zombie_football_gargantuar_body1.png", ZOMBIE_FOOTBALL_GARGANTUAR_BODY_1_2)
        "Head":
            sprite.SetReplace("Zombie_football_gargantuar_head.png", ZOMBIE_FOOTBALL_GARGANTUAR_HEAD_2)
            sprite.SetReplace("Zombie_football_gargantuar_body1.png", ZOMBIE_FOOTBALL_GARGANTUAR_BODY_1_3)
