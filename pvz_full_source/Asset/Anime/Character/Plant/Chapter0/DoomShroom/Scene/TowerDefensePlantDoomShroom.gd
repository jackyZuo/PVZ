@tool
extends TowerDefensePlant

func SleepEntered() -> void :
    super.SleepEntered()
    instance.invincible = false
