@tool
extends TowerDefensePlant

const JALA_NUT_SKIN_1_1 = preload("uid://ddk2bg2wig1ta")
const JALA_NUT_SKIN_1_2 = preload("uid://ugbibiellhqa")
const JALA_NUT_SKIN_1_3 = preload("uid://d222h4r3nut1w")
const JALA_NUT_SKIN_2_1 = preload("uid://by3vaedjvn7h8")
const JALA_NUT_SKIN_2_2 = preload("uid://bt6m0vl7yp261")
const JALA_NUT_SKIN_2_3 = preload("uid://dsauqiyf6oauj")
const JALA_NUT_SKIN_5_1 = preload("uid://coq6s5e0e1aem")
const JALA_NUT_SKIN_5_2 = preload("uid://bw4bolg1djjyl")

var over: bool = false

func DamagePointReach(damangePointName: String) -> void :
    super.DamagePointReach(damangePointName)
    match damangePointName:
        "Damage0":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("JalaNut_skin1_1.png", JALA_NUT_SKIN_1_1)
                sprite.SetReplace("JalaNut_skin2_1.png", JALA_NUT_SKIN_2_1)
                sprite.SetReplace("JalaNut_skin5_1.png", JALA_NUT_SKIN_5_1)
        "Damage1":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("JalaNut_skin1_1.png", JALA_NUT_SKIN_1_2)
                sprite.SetReplace("JalaNut_skin2_1.png", JALA_NUT_SKIN_2_2)
                sprite.SetReplace("JalaNut_skin5_1.png", JALA_NUT_SKIN_5_2)
        "Damage2":
            if currentCustom.has("Custom0"):
                sprite.SetReplace("JalaNut_skin1_1.png", JALA_NUT_SKIN_1_3)
                sprite.SetReplace("JalaNut_skin2_1.png", JALA_NUT_SKIN_2_3)
                sprite.SetFliter("skin6_1", true)

func DestroySet() -> void :
    if over:
        return
    over = true
    Explode()

func Explode() -> void :
    CreateJalapenoFire(camp, gridPos, 1800.0)
    await get_tree().physics_frame

func ExportVariantSave() -> Dictionary:
    return {
        "over": over, 
    }

func ImportVariantSave(data: Dictionary) -> void :
    over = data.get("over", false)
