class_name WeightPickItemBase extends Resource

var empty: bool = false
var item: Variant = null
var weight: float = 100

func _init(_item: Variant = null, _weight: float = 100, _empty: bool = false) -> void :
    item = _item
    weight = _weight
    empty = _empty
