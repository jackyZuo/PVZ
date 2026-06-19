class_name DropItemHandler extends Resource

@warning_ignore("unused_parameter")
func OnCollect(pos: Vector2, value: int) -> void :
    pass

@warning_ignore("unused_parameter")
func OnSpawn(pos: Vector2) -> void :
    pass

func OnDestroy() -> void :
    pass

func GetCollectValue(baseValue: int) -> int:
    return baseValue

func ShouldAutoCollect() -> bool:
    return false

func Reset() -> void :
    pass
