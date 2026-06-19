@tool
extends TowerDefenseZombieGargantuarBase

const ZOMBIE_FOOTBALL_GARGANTUAR_HEAD_2_REDEYE = preload("uid://ceopccduykwvs")
const ZOMBIE_FOOTBALL_GARGANTUAR_HEAD_REDEYE = preload("uid://byigpijs64pd")
const ZOMBIE_FOOTBALL_GARGANTUAR_R_BODY_1 = preload("uid://c3qljh4kvcs8s")
const ZOMBIE_FOOTBALL_GARGANTUAR_R_BODY_1_2 = preload("uid://pcqrhw4twpms")
const ZOMBIE_FOOTBALL_GARGANTUAR_R_BODY_1_3 = preload("uid://v14ui28vj0nv")

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Arm":
            sprite.SetReplace("Zombie_football_gargantuar_body1.png", ZOMBIE_FOOTBALL_GARGANTUAR_R_BODY_1_2)
        "Head":
            sprite.SetReplace("Zombie_football_gargantuar_head.png", ZOMBIE_FOOTBALL_GARGANTUAR_HEAD_2_REDEYE)
            sprite.SetReplace("Zombie_football_gargantuar_body1.png", ZOMBIE_FOOTBALL_GARGANTUAR_R_BODY_1_3)
