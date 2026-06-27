@tool
extends Control

var editor_plugin

const LEVEL_BASE_PATH: String = "res://Asset/Config/Level/TowerDefense/"


var level_tree: Tree
var button_refresh: Button
var button_new: Button
var button_copy: Button
var button_delete: Button
var search_line: LineEdit


var edit_scroll: ScrollContainer
var edit_vbox: VBoxContainer
var no_level_label: Label


var current_level_path: String = ""
var current_level_data: Dictionary = {}
var _loaded: bool = false
var _dirty: bool = false


var _tree_load_queue: Array = []
var _tree_loading: bool = false
var _scan_queue: Array = []
var _scan_loading: bool = false


var field_name: LineEdit
var field_level_name: LineEdit
var field_description: LineEdit
var field_level_number: SpinBox
var field_next_level: LineEdit
var option_home_world: OptionButton
var option_finish_method: OptionButton
var spin_base_time_scale: SpinBox
var check_mower_use: CheckBox
var field_talk: LineEdit
var field_tutorial: LineEdit
var option_map: OptionButton
var option_bgm: OptionButton
var check_storm_open: CheckBox


var option_reward_type: OptionButton
var field_reward_value: LineEdit


var option_packet_bank_method: OptionButton
var field_packet_bank_name: LineEdit
var check_plant_column: CheckBox
var check_cooldown_start: CheckBox
var check_cooldown_use: CheckBox
var spin_limit_grid_plant_num: SpinBox
var packet_list: ItemList
var button_add_packet: Button
var button_remove_packet: Button
var field_packet_name: LineEdit


var check_sun_open: CheckBox
var field_sun_type: LineEdit
var spin_sun_begin: SpinBox
var spin_sun_spawn_interval: SpinBox
var spin_sun_spawn_num: SpinBox
var option_sun_moving_method: OptionButton


var check_fog_open: CheckBox
var spin_fog_begin_column: SpinBox


var check_lookstar_open: CheckBox
var lookstar_list: ItemList
var button_add_lookstar: Button
var button_remove_lookstar: Button
var field_lookstar_packet_name: LineEdit
var spin_lookstar_grid_x: SpinBox
var spin_lookstar_grid_y: SpinBox


var event_init_list: ItemList
var event_ready_list: ItemList
var event_start_list: ItemList
var button_add_event_init: Button
var button_remove_event_init: Button
var button_add_event_ready: Button
var button_remove_event_ready: Button
var button_add_event_start: Button
var button_remove_event_start: Button
var field_event_name: LineEdit
var field_event_value: TextEdit


var button_save: Button


var _map_options: PackedStringArray = []
var _bgm_options: PackedStringArray = []

func _ready() -> void :
    _BuildUI()

func _process(_delta: float) -> void :
    _ProcessTreeLoad()
    _ProcessScanLoad()

func _EnsureLoaded() -> void :
    if not _loaded:
        _loaded = true
        _RefreshLevelTree()
        _ScanMapAndBGM()





func _BuildUI() -> void :
    name = "LevelEditor"
    anchor_right = 1.0
    anchor_bottom = 1.0
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL


    var hsplit = HSplitContainer.new()
    hsplit.name = "HSplit"
    hsplit.anchor_right = 1.0
    hsplit.anchor_bottom = 1.0
    hsplit.split_offset = 240
    hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(hsplit)


    var left_panel = VBoxContainer.new()
    left_panel.name = "LeftPanel"
    left_panel.custom_minimum_size = Vector2(240, 0)
    left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hsplit.add_child(left_panel)


    var search_hbox = HBoxContainer.new()
    left_panel.add_child(search_hbox)
    search_line = LineEdit.new()
    search_line.placeholder_text = "搜索关卡..."
    search_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    search_line.text_changed.connect(_on_search_changed)
    search_hbox.add_child(search_line)
    button_refresh = Button.new()
    button_refresh.tooltip_text = "刷新列表"
    button_refresh.icon = EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons")
    button_refresh.pressed.connect(_RefreshLevelTree)
    search_hbox.add_child(button_refresh)


    level_tree = Tree.new()
    level_tree.name = "LevelTree"
    level_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
    level_tree.hide_root = true
    level_tree.item_activated.connect(_on_level_activated)
    level_tree.item_selected.connect(_on_level_selected)
    left_panel.add_child(level_tree)


    var btn_hbox = HBoxContainer.new()
    left_panel.add_child(btn_hbox)
    button_new = Button.new()
    button_new.text = "新建"
    button_new.tooltip_text = "新建关卡"
    button_new.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_new.pressed.connect(_on_new_level)
    btn_hbox.add_child(button_new)
    button_copy = Button.new()
    button_copy.text = "复制"
    button_copy.tooltip_text = "复制选中关卡"
    button_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_copy.pressed.connect(_on_copy_level)
    btn_hbox.add_child(button_copy)
    button_delete = Button.new()
    button_delete.text = "删除"
    button_delete.tooltip_text = "删除选中关卡"
    button_delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button_delete.pressed.connect(_on_delete_level)
    btn_hbox.add_child(button_delete)


    var right_panel = VBoxContainer.new()
    right_panel.name = "RightPanel"
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hsplit.add_child(right_panel)


    var toolbar = HBoxContainer.new()
    right_panel.add_child(toolbar)
    var title_label = Label.new()
    title_label.text = "关卡编辑器"
    title_label.add_theme_font_size_override("font_size", 16)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    toolbar.add_child(title_label)
    button_save = Button.new()
    button_save.text = "保存"
    button_save.tooltip_text = "保存当前关卡 (Ctrl+S)"
    button_save.disabled = true
    button_save.pressed.connect(_on_save)
    toolbar.add_child(button_save)


    edit_scroll = ScrollContainer.new()
    edit_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    edit_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    right_panel.add_child(edit_scroll)

    edit_vbox = VBoxContainer.new()
    edit_vbox.name = "EditVBox"
    edit_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    edit_scroll.add_child(edit_vbox)


    no_level_label = Label.new()
    no_level_label.text = "请从左侧选择一个关卡"
    no_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    no_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    no_level_label.anchor_right = 1.0
    no_level_label.anchor_bottom = 1.0
    no_level_label.add_theme_font_size_override("font_size", 18)
    right_panel.add_child(no_level_label)


    _BuildBaseSection()
    _BuildRewardSection()
    _BuildPacketBankSection()
    _BuildSunSection()
    _BuildFogSection()
    _BuildLookStarSection()
    _BuildEventSection()

    edit_vbox.visible = false


    var save_shortcut = Shortcut.new()
    var save_event = InputEventKey.new()
    save_event.keycode = KEY_S
    save_event.ctrl_pressed = true
    save_shortcut.events.append(save_event)
    button_save.shortcut = save_shortcut



func _BuildBaseSection() -> void :
    var section = _AddSection("基础属性")
    _AddLabelAndField(section, "名称 (Name):", func(c):
        field_name = LineEdit.new()
        field_name.text_changed.connect(_on_field_changed)
        c.add_child(field_name)
    )
    _AddLabelAndField(section, "关卡名 (LevelName):", func(c):
        field_level_name = LineEdit.new()
        field_level_name.text_changed.connect(_on_field_changed)
        c.add_child(field_level_name)
    )
    _AddLabelAndField(section, "描述 (Description):", func(c):
        field_description = LineEdit.new()
        field_description.text_changed.connect(_on_field_changed)
        c.add_child(field_description)
    )
    _AddLabelAndField(section, "关卡编号:", func(c):
        field_level_number = SpinBox.new()
        field_level_number.min_value = 1
        field_level_number.max_value = 999
        field_level_number.step = 1
        field_level_number.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(field_level_number)
    )
    _AddLabelAndField(section, "下一关 (NextLevel):", func(c):
        field_next_level = LineEdit.new()
        field_next_level.text_changed.connect(_on_field_changed)
        c.add_child(field_next_level)
    )
    _AddLabelAndField(section, "世界 (HomeWorld):", func(c):
        option_home_world = OptionButton.new()
        option_home_world.add_item("NOONE", 0)
        option_home_world.add_item("Morden", 1)
        option_home_world.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_home_world)
    )
    _AddLabelAndField(section, "完成方式:", func(c):
        option_finish_method = OptionButton.new()
        option_finish_method.add_item("WAVE", 0)
        option_finish_method.add_item("VASE", 1)
        option_finish_method.add_item("IZM", 2)
        option_finish_method.add_item("QUIZ", 3)
        option_finish_method.add_item("IZM2", 4)
        option_finish_method.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_finish_method)
    )
    _AddLabelAndField(section, "时间倍率:", func(c):
        spin_base_time_scale = SpinBox.new()
        spin_base_time_scale.min_value = 0.1
        spin_base_time_scale.max_value = 10.0
        spin_base_time_scale.step = 0.1
        spin_base_time_scale.value = 1.0
        spin_base_time_scale.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(spin_base_time_scale)
    )
    _AddLabelAndField(section, "割草机:", func(c):
        check_mower_use = CheckBox.new()
        check_mower_use.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_mower_use)
    )
    _AddLabelAndField(section, "对话 (Talk):", func(c):
        field_talk = LineEdit.new()
        field_talk.text_changed.connect(_on_field_changed)
        c.add_child(field_talk)
    )
    _AddLabelAndField(section, "教程 (Tutorial):", func(c):
        field_tutorial = LineEdit.new()
        field_tutorial.text_changed.connect(_on_field_changed)
        c.add_child(field_tutorial)
    )
    _AddLabelAndField(section, "地图 (Map):", func(c):
        option_map = OptionButton.new()
        option_map.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_map)
    )
    _AddLabelAndField(section, "BGM:", func(c):
        option_bgm = OptionButton.new()
        option_bgm.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_bgm)
    )
    _AddLabelAndField(section, "暴风雨:", func(c):
        check_storm_open = CheckBox.new()
        check_storm_open.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_storm_open)
    )



func _BuildRewardSection() -> void :
    var section = _AddSection("奖励")
    _AddLabelAndField(section, "奖励类型:", func(c):
        option_reward_type = OptionButton.new()
        option_reward_type.add_item("NOONE", 0)
        option_reward_type.add_item("Packet", 1)
        option_reward_type.add_item("Collectable", 2)
        option_reward_type.add_item("Coin", 3)
        option_reward_type.add_item("Trophy", 4)
        option_reward_type.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_reward_type)
    )
    _AddLabelAndField(section, "奖励值:", func(c):
        field_reward_value = LineEdit.new()
        field_reward_value.text_changed.connect(_on_field_changed)
        c.add_child(field_reward_value)
    )



func _BuildPacketBankSection() -> void :
    var section = _AddSection("种子库")
    _AddLabelAndField(section, "方式 (Method):", func(c):
        option_packet_bank_method = OptionButton.new()
        option_packet_bank_method.add_item("NOONE", 0)
        option_packet_bank_method.add_item("CHOOSE", 1)
        option_packet_bank_method.add_item("PRESET", 2)
        option_packet_bank_method.add_item("CONVEYOR", 3)
        option_packet_bank_method.add_item("RAIN", 4)
        option_packet_bank_method.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_packet_bank_method)
    )
    _AddLabelAndField(section, "种子库名称:", func(c):
        field_packet_bank_name = LineEdit.new()
        field_packet_bank_name.text_changed.connect(_on_field_changed)
        c.add_child(field_packet_bank_name)
    )
    _AddLabelAndField(section, "植物列排列:", func(c):
        check_plant_column = CheckBox.new()
        check_plant_column.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_plant_column)
    )
    _AddLabelAndField(section, "冷却起始:", func(c):
        check_cooldown_start = CheckBox.new()
        check_cooldown_start.button_pressed = true
        check_cooldown_start.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_cooldown_start)
    )
    _AddLabelAndField(section, "冷却使用:", func(c):
        check_cooldown_use = CheckBox.new()
        check_cooldown_use.button_pressed = true
        check_cooldown_use.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_cooldown_use)
    )
    _AddLabelAndField(section, "格子植物上限:", func(c):
        spin_limit_grid_plant_num = SpinBox.new()
        spin_limit_grid_plant_num.min_value = -1
        spin_limit_grid_plant_num.max_value = 999
        spin_limit_grid_plant_num.value = -1
        spin_limit_grid_plant_num.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(spin_limit_grid_plant_num)
    )


    var packet_label = Label.new()
    packet_label.text = "卡片列表 (Value):"
    section.add_child(packet_label)

    packet_list = ItemList.new()
    packet_list.custom_minimum_size = Vector2(0, 120)
    packet_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_child(packet_list)

    var packet_btn_hbox = HBoxContainer.new()
    section.add_child(packet_btn_hbox)
    field_packet_name = LineEdit.new()
    field_packet_name.placeholder_text = "植物名称 (如 PlantPeashooter)"
    field_packet_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    packet_btn_hbox.add_child(field_packet_name)
    button_add_packet = Button.new()
    button_add_packet.text = "添加"
    button_add_packet.pressed.connect(_on_add_packet)
    packet_btn_hbox.add_child(button_add_packet)
    button_remove_packet = Button.new()
    button_remove_packet.text = "移除"
    button_remove_packet.pressed.connect(_on_remove_packet)
    packet_btn_hbox.add_child(button_remove_packet)



func _BuildSunSection() -> void :
    var section = _AddSection("阳光管理器")
    _AddLabelAndField(section, "开启:", func(c):
        check_sun_open = CheckBox.new()
        check_sun_open.button_pressed = true
        check_sun_open.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_sun_open)
    )
    _AddLabelAndField(section, "类型:", func(c):
        field_sun_type = LineEdit.new()
        field_sun_type.text = "Normal"
        field_sun_type.text_changed.connect(_on_field_changed)
        c.add_child(field_sun_type)
    )
    _AddLabelAndField(section, "初始阳光:", func(c):
        spin_sun_begin = SpinBox.new()
        spin_sun_begin.min_value = 0
        spin_sun_begin.max_value = 99999
        spin_sun_begin.value = 300
        spin_sun_begin.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(spin_sun_begin)
    )
    _AddLabelAndField(section, "掉落间隔:", func(c):
        spin_sun_spawn_interval = SpinBox.new()
        spin_sun_spawn_interval.min_value = 0.1
        spin_sun_spawn_interval.max_value = 999.0
        spin_sun_spawn_interval.step = 0.5
        spin_sun_spawn_interval.value = 12.0
        spin_sun_spawn_interval.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(spin_sun_spawn_interval)
    )
    _AddLabelAndField(section, "掉落数值:", func(c):
        spin_sun_spawn_num = SpinBox.new()
        spin_sun_spawn_num.min_value = 0
        spin_sun_spawn_num.max_value = 9999
        spin_sun_spawn_num.value = 50
        spin_sun_spawn_num.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(spin_sun_spawn_num)
    )
    _AddLabelAndField(section, "移动方式:", func(c):
        option_sun_moving_method = OptionButton.new()
        option_sun_moving_method.add_item("LAND", 0)
        option_sun_moving_method.add_item("SKY", 1)
        option_sun_moving_method.item_selected.connect( func(_i): _on_field_changed(""))
        c.add_child(option_sun_moving_method)
    )



func _BuildFogSection() -> void :
    var section = _AddSection("迷雾管理器")
    _AddLabelAndField(section, "开启:", func(c):
        check_fog_open = CheckBox.new()
        check_fog_open.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_fog_open)
    )
    _AddLabelAndField(section, "起始列:", func(c):
        spin_fog_begin_column = SpinBox.new()
        spin_fog_begin_column.min_value = 0
        spin_fog_begin_column.max_value = 20
        spin_fog_begin_column.value = 5
        spin_fog_begin_column.value_changed.connect( func(_v): _on_field_changed(""))
        c.add_child(spin_fog_begin_column)
    )



func _BuildLookStarSection() -> void :
    var section = _AddSection("观星管理器")
    _AddLabelAndField(section, "开启:", func(c):
        check_lookstar_open = CheckBox.new()
        check_lookstar_open.button_toggled.connect( func(_b): _on_field_changed(""))
        c.add_child(check_lookstar_open)
    )

    var ls_label = Label.new()
    ls_label.text = "检查列表 (Check):"
    section.add_child(ls_label)

    lookstar_list = ItemList.new()
    lookstar_list.custom_minimum_size = Vector2(0, 100)
    lookstar_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_child(lookstar_list)

    var ls_hbox = HBoxContainer.new()
    section.add_child(ls_hbox)
    field_lookstar_packet_name = LineEdit.new()
    field_lookstar_packet_name.placeholder_text = "PacketName"
    field_lookstar_packet_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ls_hbox.add_child(field_lookstar_packet_name)
    spin_lookstar_grid_x = SpinBox.new()
    spin_lookstar_grid_x.min_value = 0
    spin_lookstar_grid_x.max_value = 20
    spin_lookstar_grid_x.prefix = "X:"
    ls_hbox.add_child(spin_lookstar_grid_x)
    spin_lookstar_grid_y = SpinBox.new()
    spin_lookstar_grid_y.min_value = 0
    spin_lookstar_grid_y.max_value = 20
    spin_lookstar_grid_y.prefix = "Y:"
    ls_hbox.add_child(spin_lookstar_grid_y)
    button_add_lookstar = Button.new()
    button_add_lookstar.text = "添加"
    button_add_lookstar.pressed.connect(_on_add_lookstar)
    ls_hbox.add_child(button_add_lookstar)
    button_remove_lookstar = Button.new()
    button_remove_lookstar.text = "移除"
    button_remove_lookstar.pressed.connect(_on_remove_lookstar)
    ls_hbox.add_child(button_remove_lookstar)



func _BuildEventSection() -> void :
    var section = _AddSection("事件")


    var init_label = Label.new()
    init_label.text = "EventInit:"
    section.add_child(init_label)
    event_init_list = ItemList.new()
    event_init_list.custom_minimum_size = Vector2(0, 80)
    event_init_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_child(event_init_list)
    var init_btn_hbox = HBoxContainer.new()
    section.add_child(init_btn_hbox)
    button_add_event_init = Button.new()
    button_add_event_init.text = "添加"
    button_add_event_init.pressed.connect( func(): _on_add_event("init"))
    init_btn_hbox.add_child(button_add_event_init)
    button_remove_event_init = Button.new()
    button_remove_event_init.text = "移除"
    button_remove_event_init.pressed.connect( func(): _on_remove_event("init"))
    init_btn_hbox.add_child(button_remove_event_init)


    var ready_label = Label.new()
    ready_label.text = "EventReady:"
    section.add_child(ready_label)
    event_ready_list = ItemList.new()
    event_ready_list.custom_minimum_size = Vector2(0, 80)
    event_ready_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_child(event_ready_list)
    var ready_btn_hbox = HBoxContainer.new()
    section.add_child(ready_btn_hbox)
    button_add_event_ready = Button.new()
    button_add_event_ready.text = "添加"
    button_add_event_ready.pressed.connect( func(): _on_add_event("ready"))
    ready_btn_hbox.add_child(button_add_event_ready)
    button_remove_event_ready = Button.new()
    button_remove_event_ready.text = "移除"
    button_remove_event_ready.pressed.connect( func(): _on_remove_event("ready"))
    ready_btn_hbox.add_child(button_remove_event_ready)


    var start_label = Label.new()
    start_label.text = "EventStart:"
    section.add_child(start_label)
    event_start_list = ItemList.new()
    event_start_list.custom_minimum_size = Vector2(0, 80)
    event_start_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_child(event_start_list)
    var start_btn_hbox = HBoxContainer.new()
    section.add_child(start_btn_hbox)
    button_add_event_start = Button.new()
    button_add_event_start.text = "添加"
    button_add_event_start.pressed.connect( func(): _on_add_event("start"))
    start_btn_hbox.add_child(button_add_event_start)
    button_remove_event_start = Button.new()
    button_remove_event_start.text = "移除"
    button_remove_event_start.pressed.connect( func(): _on_remove_event("start"))
    start_btn_hbox.add_child(button_remove_event_start)


    var ev_edit_label = Label.new()
    ev_edit_label.text = "事件编辑 (选中事件后编辑):"
    section.add_child(ev_edit_label)
    _AddLabelAndField(section, "事件名称:", func(c):
        field_event_name = LineEdit.new()
        field_event_name.placeholder_text = "EventName"
        field_event_name.text_changed.connect(_on_field_changed)
        c.add_child(field_event_name)
    )
    var val_label = Label.new()
    val_label.text = "事件值 (JSON):"
    section.add_child(val_label)
    field_event_value = TextEdit.new()
    field_event_value.custom_minimum_size = Vector2(0, 80)
    field_event_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    field_event_value.text_changed.connect(_on_field_changed)
    section.add_child(field_event_value)





func _AddSection(title: String) -> VBoxContainer:
    var section = VBoxContainer.new()
    section.name = title
    section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit_vbox.add_child(section)


    var hsep = HSeparator.new()
    section.add_child(hsep)

    var header = Label.new()
    header.text = title
    header.add_theme_font_size_override("font_size", 14)
    section.add_child(header)

    return section

func _AddLabelAndField(parent: VBoxContainer, label_text: String, build_field: Callable) -> void :
    var hbox = HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(hbox)
    var label = Label.new()
    label.text = label_text
    label.custom_minimum_size = Vector2(140, 0)
    hbox.add_child(label)
    var child_count_before = hbox.get_child_count()
    build_field.call(hbox)

    for i in range(child_count_before, hbox.get_child_count()):
        var child = hbox.get_child(i)
        child.size_flags_horizontal = Control.SIZE_EXPAND_FILL





func _ScanMapAndBGM() -> void :
    _map_options.clear()
    _bgm_options.clear()
    _scan_queue.clear()
    _scan_loading = true


    var dirs_to_scan: Array = [{"path": LEVEL_BASE_PATH, "depth": 0}]
    while not dirs_to_scan.is_empty():
        var item = dirs_to_scan.pop_front()
        var path: String = item["path"]
        var dir = DirAccess.open(path)
        if not dir:
            continue
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir() and not file_name.begins_with("."):
                dirs_to_scan.append({"path": path + file_name + "/", "depth": item["depth"] + 1})
            elif file_name.ends_with(".json"):
                _scan_queue.append(path + file_name)
            file_name = dir.get_next()
        dir.list_dir_end()

func _ProcessScanLoad() -> void :
    if not _scan_loading:
        return

    var batch_size = 5
    for i in batch_size:
        if _scan_queue.is_empty():
            _FinishScanLoad()
            return
        var file_path: String = _scan_queue.pop_front()
        var json_data = _LoadJSON(file_path)
        if not json_data.is_empty():
            var map_val = json_data.get("Map", "")
            var bgm_val = json_data.get("BGM", "")
            if map_val != "" and not map_val in _map_options:
                _map_options.append(map_val)
            if bgm_val != "" and not bgm_val in _bgm_options:
                _bgm_options.append(bgm_val)

func _FinishScanLoad() -> void :
    _scan_loading = false

    var map_set: Dictionary = {}
    var bgm_set: Dictionary = {}
    for m in _map_options:
        map_set[m] = true
    for b in _bgm_options:
        bgm_set[b] = true
    _map_options = PackedStringArray()
    for m in map_set.keys():
        _map_options.append(m)
    _map_options.sort()
    _bgm_options = PackedStringArray()
    for b in bgm_set.keys():
        _bgm_options.append(b)
    _bgm_options.sort()


    option_map.clear()
    option_map.add_item("(自定义)", 0)
    for i in _map_options.size():
        option_map.add_item(_map_options[i], i + 1)
    option_bgm.clear()
    option_bgm.add_item("(自定义)", 0)
    for i in _bgm_options.size():
        option_bgm.add_item(_bgm_options[i], i + 1)





func _RefreshLevelTree() -> void :
    level_tree.clear()
    var root = level_tree.create_item()
    _tree_load_queue.clear()
    _tree_loading = true


    var dir = DirAccess.open(LEVEL_BASE_PATH)
    if not dir:
        _tree_loading = false
        return

    dir.list_dir_begin()
    var dir_name = dir.get_next()
    while dir_name != "":
        if dir.current_is_dir() and not dir_name.begins_with("."):
            var category_item = level_tree.create_item(root)
            category_item.set_text(0, dir_name)
            category_item.set_selectable(0, false)
            _tree_load_queue.append({"parent_item": category_item, "sub_path": LEVEL_BASE_PATH + dir_name + "/"})
        dir_name = dir.get_next()
    dir.list_dir_end()

func _ProcessTreeLoad() -> void :
    if not _tree_loading:
        return
    if _tree_load_queue.is_empty():
        _tree_loading = false
        return

    var item = _tree_load_queue.pop_front()
    var parent_item: TreeItem = item["parent_item"]
    var sub_path: String = item["sub_path"]
    var sub_dir = DirAccess.open(sub_path)
    if sub_dir:
        sub_dir.list_dir_begin()
        var file_name = sub_dir.get_next()
        while file_name != "":
            if dir_current_is_dir(sub_dir, sub_path, file_name):

                var sub_category_item = level_tree.create_item(parent_item)
                sub_category_item.set_text(0, file_name)
                sub_category_item.set_selectable(0, false)
                _tree_load_queue.append({"parent_item": sub_category_item, "sub_path": sub_path + file_name + "/"})
            elif file_name.ends_with(".json"):
                var level_item = level_tree.create_item(parent_item)
                level_item.set_text(0, file_name.get_basename())
                level_item.set_metadata(0, sub_path + file_name)
            file_name = sub_dir.get_next()
        sub_dir.list_dir_end()

func dir_current_is_dir(dir: DirAccess, base_path: String, name: String) -> bool:
    if dir.current_is_dir():
        return true

    return DirAccess.dir_exists_absolute(base_path + name)

func _on_search_changed(new_text: String) -> void :
    _RefreshLevelTree()
    if new_text.is_empty():
        return
    var root = level_tree.get_root()
    if not root:
        return
    var child = root.get_first_child()
    while child:
        _RecursiveFilter(child, new_text)
        child = child.get_next()

func _RecursiveFilter(item: TreeItem, search_text: String) -> bool:
    var has_visible = false
    var child = item.get_first_child()
    while child:
        if _RecursiveFilter(child, search_text):
            has_visible = true
        child = child.get_next()

    if not has_visible and item.get_metadata(0):
        if item.get_text(0).findn(search_text) >= 0:
            item.visible = true
            has_visible = true
        else:
            item.visible = false
    else:
        item.visible = has_visible
    return has_visible

func _on_level_activated() -> void :
    _on_level_selected()

func _on_level_selected() -> void :
    var selected = level_tree.get_selected()
    if not selected or not selected.get_metadata(0):
        return
    var path: String = selected.get_metadata(0)
    _LoadLevel(path)





func _LoadJSON(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}
    var json_text = file.get_as_text()
    file.close()
    var json = JSON.new()
    if json.parse(json_text) != OK:
        return {}
    return json.data as Dictionary

func _LoadLevel(path: String) -> void :

    if _dirty and current_level_path != "":
        var dialog = ConfirmationDialog.new()
        dialog.title = "未保存的修改"
        dialog.dialog_text = "当前关卡有未保存的修改，是否放弃？"
        dialog.confirmed.connect( func(): _DoLoadLevel(path))
        dialog.ok_button_text = "放弃修改"
        add_child(dialog)
        dialog.popup_centered()
        dialog.tree_exited.connect(dialog.queue_free)
    else:
        _DoLoadLevel(path)

func _DoLoadLevel(path: String) -> void :
    current_level_path = path
    current_level_data = _LoadJSON(path)
    if current_level_data.is_empty():
        push_warning("[LevelEditor] Failed to load: " + path)
        return
    _dirty = false
    button_save.disabled = true
    _PopulateFields()
    edit_vbox.visible = true
    no_level_label.visible = false

func _PopulateFields() -> void :
    var d = current_level_data

    field_name.text = str(d.get("Name", ""))
    field_level_name.text = str(d.get("LevelName", ""))
    field_description.text = str(d.get("Description", ""))
    field_level_number.value = float(d.get("LevelNumber", 1))
    field_next_level.text = str(d.get("NextLevel", ""))


    var hw = str(d.get("HomeWorld", "NOONE")).to_upper()
    match hw:
        "MORDEN": option_home_world.select(1)
        _: option_home_world.select(0)


    var fm = str(d.get("FinishMethod", "WAVE")).to_upper()
    match fm:
        "WAVE": option_finish_method.select(0)
        "VASE": option_finish_method.select(1)
        "IZM": option_finish_method.select(2)
        "QUIZ": option_finish_method.select(3)
        "IZM2": option_finish_method.select(4)
        _: option_finish_method.select(0)

    spin_base_time_scale.value = float(d.get("BaseTimeScale", 1.0))
    check_mower_use.button_pressed = bool(d.get("MowerUse", true))
    field_talk.text = str(d.get("Talk", ""))
    field_tutorial.text = str(d.get("Tutorial", ""))


    var map_val = str(d.get("Map", ""))
    var map_idx = _map_options.find(map_val)
    if map_idx >= 0:
        option_map.select(map_idx + 1)
    else:
        option_map.select(0)


    var bgm_val = str(d.get("BGM", ""))
    var bgm_idx = _bgm_options.find(bgm_val)
    if bgm_idx >= 0:
        option_bgm.select(bgm_idx + 1)
    else:
        option_bgm.select(0)

    check_storm_open.button_pressed = bool(d.get("StormOpen", false))


    var reward: Dictionary = d.get("Reward", {})
    var rt = str(reward.get("RewardType", "NOONE")).to_upper()
    match rt:
        "NOONE": option_reward_type.select(0)
        "PACKET": option_reward_type.select(1)
        "COLLECTABLE": option_reward_type.select(2)
        "COIN": option_reward_type.select(3)
        "TROPHY": option_reward_type.select(4)
        _: option_reward_type.select(0)
    field_reward_value.text = str(reward.get("RewardFirst", ""))


    var pb: Dictionary = d.get("PacketBank", {})
    var pbm = str(pb.get("Method", "NOONE")).to_upper()
    match pbm:
        "NOONE": option_packet_bank_method.select(0)
        "CHOOSE": option_packet_bank_method.select(1)
        "PRESET": option_packet_bank_method.select(2)
        "CONVEYOR": option_packet_bank_method.select(3)
        "RAIN": option_packet_bank_method.select(4)
        _: option_packet_bank_method.select(0)
    field_packet_bank_name.text = str(pb.get("Type", ""))
    check_plant_column.button_pressed = bool(pb.get("PlantColumn", false))
    check_cooldown_start.button_pressed = bool(pb.get("ColdDownStart", true))
    check_cooldown_use.button_pressed = bool(pb.get("ColdDownUse", true))
    spin_limit_grid_plant_num.value = int(pb.get("LimitGridPlantNum", -1))


    packet_list.clear()
    var pb_value: Array = pb.get("Value", [])
    for item in pb_value:
        if item is Dictionary:
            var pn = str(item.get("PacketName", item.get("Name", "")))
            packet_list.add_item(pn)
        elif item is String:
            packet_list.add_item(item)


    var sun: Dictionary = d.get("SunManager", {})
    check_sun_open.button_pressed = bool(sun.get("Open", true))
    field_sun_type.text = str(sun.get("Type", "Normal"))
    spin_sun_begin.value = float(sun.get("Begin", 300))
    spin_sun_spawn_interval.value = float(sun.get("SpawnInterval", 12.0))
    spin_sun_spawn_num.value = float(sun.get("SpawnNum", 50))
    var smm = str(sun.get("MovingMethod", "LAND")).to_upper()
    match smm:
        "LAND": option_sun_moving_method.select(0)
        "SKY": option_sun_moving_method.select(1)
        _: option_sun_moving_method.select(0)


    var fog: Dictionary = d.get("FogManager", {})
    check_fog_open.button_pressed = bool(fog.get("Open", false))
    spin_fog_begin_column.value = int(fog.get("BeginColumn", 5))


    var ls: Dictionary = d.get("LookStarManager", {})
    check_lookstar_open.button_pressed = bool(ls.get("Open", false))
    lookstar_list.clear()
    var check_list: Array = ls.get("Check", [])
    for check_item in check_list:
        if check_item is Dictionary:
            var pn = str(check_item.get("PacketName", ""))
            var gp = check_item.get("GridPos", [0, 0])
            lookstar_list.add_item("%s (%s,%s)" % [pn, str(gp[0]), str(gp[1])])


    var ev: Dictionary = d.get("Event", {})
    _PopulateEventList(event_init_list, ev.get("EventInit", []))
    _PopulateEventList(event_ready_list, ev.get("EventReady", []))
    _PopulateEventList(event_start_list, ev.get("EventStart", []))

func _PopulateEventList(list: ItemList, events: Array) -> void :
    list.clear()
    for ev_item in events:
        if ev_item is Dictionary:
            var en = str(ev_item.get("EventName", ""))
            list.add_item(en)

func _CollectFields() -> Dictionary:
    var d: Dictionary = {}

    d["Name"] = field_name.text
    d["LevelName"] = field_level_name.text
    d["Description"] = field_description.text
    d["LevelNumber"] = field_level_number.value
    d["NextLevel"] = field_next_level.text


    var hw_idx = option_home_world.get_selected_id()
    match hw_idx:
        0: d["HomeWorld"] = "NOONE"
        1: d["HomeWorld"] = "Morden"


    var fm_idx = option_finish_method.get_selected_id()
    match fm_idx:
        0: d["FinishMethod"] = "WAVE"
        1: d["FinishMethod"] = "VASE"
        2: d["FinishMethod"] = "IZM"
        3: d["FinishMethod"] = "QUIZ"
        4: d["FinishMethod"] = "IZM2"

    d["BaseTimeScale"] = spin_base_time_scale.value
    d["MowerUse"] = check_mower_use.button_pressed
    d["Talk"] = field_talk.text
    d["Tutorial"] = field_tutorial.text


    var map_id = option_map.get_selected_id()
    if map_id > 0 and map_id - 1 < _map_options.size():
        d["Map"] = _map_options[map_id - 1]
    else:
        d["Map"] = ""


    var bgm_id = option_bgm.get_selected_id()
    if bgm_id > 0 and bgm_id - 1 < _bgm_options.size():
        d["BGM"] = _bgm_options[bgm_id - 1]
    else:
        d["BGM"] = ""

    d["StormOpen"] = check_storm_open.button_pressed


    var rt_idx = option_reward_type.get_selected_id()
    var rt_str = "NOONE"
    match rt_idx:
        0: rt_str = "NOONE"
        1: rt_str = "Packet"
        2: rt_str = "Collectable"
        3: rt_str = "Coin"
        4: rt_str = "Trophy"
    d["Reward"] = {
        "RewardType": rt_str, 
        "RewardFirst": field_reward_value.text
    }


    var pbm_idx = option_packet_bank_method.get_selected_id()
    var pbm_str = "NOONE"
    match pbm_idx:
        0: pbm_str = "NOONE"
        1: pbm_str = "CHOOSE"
        2: pbm_str = "PRESET"
        3: pbm_str = "CONVEYOR"
        4: pbm_str = "RAIN"

    var pb_value: Array = []
    for i in packet_list.item_count:
        pb_value.append(packet_list.get_item_text(i))

    d["PacketBank"] = {
        "LimitGridPlantNum": int(spin_limit_grid_plant_num.value), 
        "PlantColumn": check_plant_column.button_pressed, 
        "ColdDownStart": check_cooldown_start.button_pressed, 
        "ColdDownUse": check_cooldown_use.button_pressed, 
        "Method": pbm_str, 
        "Type": field_packet_bank_name.text, 
        "Value": pb_value
    }


    var smm_idx = option_sun_moving_method.get_selected_id()
    var smm_str = "LAND"
    match smm_idx:
        0: smm_str = "LAND"
        1: smm_str = "SKY"
    d["SunManager"] = {
        "Open": check_sun_open.button_pressed, 
        "Type": field_sun_type.text, 
        "Begin": spin_sun_begin.value, 
        "SpawnInterval": spin_sun_spawn_interval.value, 
        "SpawnNum": spin_sun_spawn_num.value, 
        "MovingMethod": smm_str
    }


    d["FogManager"] = {
        "Open": check_fog_open.button_pressed, 
        "BeginColumn": int(spin_fog_begin_column.value)
    }


    var check_arr: Array = []
    for i in lookstar_list.item_count:
        var text = lookstar_list.get_item_text(i)

        var paren_idx = text.find("(")
        if paren_idx > 0:
            var pn = text.substr(0, paren_idx).strip_edges()
            var coord_str = text.substr(paren_idx + 1, text.length() - paren_idx - 2)
            var parts = coord_str.split(",")
            var gx = int(parts[0]) if parts.size() > 0 else 0
            var gy = int(parts[1]) if parts.size() > 1 else 0
            check_arr.append({"PacketName": pn, "GridPos": [gx, gy]})
    d["LookStarManager"] = {
        "Open": check_lookstar_open.button_pressed, 
        "Check": check_arr
    }


    var orig_ev: Dictionary = current_level_data.get("Event", {})
    d["Event"] = {
        "EventInit": _CollectEventList(event_init_list, orig_ev.get("EventInit", [])), 
        "EventReady": _CollectEventList(event_ready_list, orig_ev.get("EventReady", [])), 
        "EventStart": _CollectEventList(event_start_list, orig_ev.get("EventStart", []))
    }


    if current_level_data.has("WaveManager"):
        d["WaveManager"] = current_level_data["WaveManager"]
    if current_level_data.has("VaseManager"):
        d["VaseManager"] = current_level_data["VaseManager"]
    if current_level_data.has("IZMManager"):
        d["IZMManager"] = current_level_data["IZMManager"]
    if current_level_data.has("PreSpawn"):
        d["PreSpawn"] = current_level_data["PreSpawn"]

    return d

func _CollectEventList(list: ItemList, orig_events: Array) -> Array:
    var result: Array = []
    for i in list.item_count:
        var en = list.get_item_text(i)

        var found = false
        for orig in orig_events:
            if orig is Dictionary and str(orig.get("EventName", "")) == en:
                result.append(orig)
                found = true
                break
        if not found:
            result.append({"EventName": en, "Value": {}})
    return result

func _on_save() -> void :
    if current_level_path.is_empty():
        return
    var data = _CollectFields()

    for key in current_level_data:
        if not data.has(key):
            data[key] = current_level_data[key]

    var json_text = JSON.stringify(data, "\t")
    var file = FileAccess.open(current_level_path, FileAccess.WRITE)
    if file:
        file.store_string(json_text)
        file.close()
        _dirty = false
        button_save.disabled = true
        current_level_data = data
        print("[LevelEditor] Saved: ", current_level_path)
    else:
        push_error("[LevelEditor] Failed to save: " + current_level_path)

func _on_field_changed(_new_text: String = "") -> void :
    if current_level_path.is_empty():
        return
    _dirty = true
    button_save.disabled = false





func _on_add_packet() -> void :
    var name = field_packet_name.text.strip_edges()
    if name.is_empty():
        return
    packet_list.add_item(name)
    field_packet_name.text = ""
    _on_field_changed()

func _on_remove_packet() -> void :
    var selected = packet_list.get_selected_items()
    if selected.size() > 0:
        packet_list.remove_item(selected[0])
        _on_field_changed()





func _on_add_lookstar() -> void :
    var pn = field_lookstar_packet_name.text.strip_edges()
    if pn.is_empty():
        return
    var gx = int(spin_lookstar_grid_x.value)
    var gy = int(spin_lookstar_grid_y.value)
    lookstar_list.add_item("%s (%s,%s)" % [pn, str(gx), str(gy)])
    field_lookstar_packet_name.text = ""
    _on_field_changed()

func _on_remove_lookstar() -> void :
    var selected = lookstar_list.get_selected_items()
    if selected.size() > 0:
        lookstar_list.remove_item(selected[0])
        _on_field_changed()





func _on_add_event(category: String) -> void :
    var en = field_event_name.text.strip_edges()
    if en.is_empty():
        return
    var list: ItemList
    match category:
        "init": list = event_init_list
        "ready": list = event_ready_list
        "start": list = event_start_list
    list.add_item(en)
    _on_field_changed()

func _on_remove_event(category: String) -> void :
    var list: ItemList
    match category:
        "init": list = event_init_list
        "ready": list = event_ready_list
        "start": list = event_start_list
    var selected = list.get_selected_items()
    if selected.size() > 0:
        list.remove_item(selected[0])
        _on_field_changed()





func _on_new_level() -> void :
    var dialog = ConfirmationDialog.new()
    dialog.title = "新建关卡"
    dialog.min_size = Vector2i(350, 200)

    var name_label = Label.new()
    name_label.text = "关卡名称 (如 Level6_1):"
    dialog.add_child(name_label)

    var name_input = LineEdit.new()
    name_input.placeholder_text = "LevelX_X"
    dialog.add_child(name_input)

    var chapter_label = Label.new()
    chapter_label.text = "章节目录 (如 Chapter6):"
    dialog.add_child(chapter_label)

    var chapter_input = LineEdit.new()
    chapter_input.placeholder_text = "ChapterX"
    chapter_input.text = "Chapter1"
    dialog.add_child(chapter_input)

    dialog.register_text_enter(name_input)

    dialog.confirmed.connect( func():
        var level_name = name_input.text.strip_edges()
        var chapter = chapter_input.text.strip_edges()
        if level_name.is_empty() or chapter.is_empty():
            return
        var dir_path = LEVEL_BASE_PATH + chapter + "/"
        if not DirAccess.dir_exists_absolute(dir_path):
            DirAccess.make_dir_recursive_absolute(dir_path)
        var file_path = dir_path + level_name + ".json"
        if FileAccess.file_exists(file_path):
            push_warning("[LevelEditor] File already exists: " + file_path)
            return
        var default_data = {
            "Name": level_name, 
            "Description": "", 
            "LevelName": "", 
            "LevelNumber": 1.0, 
            "NextLevel": "", 
            "HomeWorld": "Morden", 
            "FinishMethod": "WAVE", 
            "Talk": "", 
            "Tutorial": "", 
            "Map": "Frontlawn", 
            "BGM": "Frontlawn", 
            "MowerUse": true, 
            "StormOpen": false, 
            "Reward": {"RewardType": "NOONE", "RewardFirst": ""}, 
            "Event": {"EventInit": [], "EventReady": [], "EventStart": []}, 
            "PacketBank": {"LimitGridPlantNum": -1, "PlantColumn": false, "ColdDownStart": true, "ColdDownUse": true, "Method": "CHOOSE", "Type": "GeneralPlant", "Value": []}, 
            "SunManager": {"Open": true, "Type": "Normal", "Begin": 300.0, "SpawnInterval": 12.0, "SpawnNum": 50.0, "MovingMethod": "LAND"}, 
            "FogManager": {"Open": false, "BeginColumn": 5}, 
            "LookStarManager": {"Open": false, "Check": []}, 
            "WaveManager": {"FlagZombie": "ZombieFlag", "FlagWaveInterval": 5.0, "MaxNextWaveHealthPercentage": 0.15, "MinNextWaveHealthPercentage": 0.1, "BeginCol": 6.0, "SpawnColEnd": 20.0, "SpawnColStart": 10.0, "Dynamic": [], "Wave": []}
        }
        var json_text = JSON.stringify(default_data, "\t")
        var file = FileAccess.open(file_path, FileAccess.WRITE)
        if file:
            file.store_string(json_text)
            file.close()
            _RefreshLevelTree()
            _DoLoadLevel(file_path)
    )

    dialog.ok_button_text = "确定"
    add_child(dialog)
    dialog.popup_centered()
    dialog.tree_exited.connect(dialog.queue_free)

func _on_copy_level() -> void :
    var selected = level_tree.get_selected()
    if not selected or not selected.get_metadata(0):
        return
    var src_path: String = selected.get_metadata(0)

    var dialog = ConfirmationDialog.new()
    dialog.title = "复制关卡"
    dialog.min_size = Vector2i(350, 150)

    var name_label = Label.new()
    name_label.text = "新关卡名称:"
    dialog.add_child(name_label)

    var name_input = LineEdit.new()
    name_input.text = selected.get_text(0) + "_Copy"
    dialog.add_child(name_input)

    dialog.register_text_enter(name_input)

    dialog.confirmed.connect( func():
        var new_name = name_input.text.strip_edges()
        if new_name.is_empty():
            return
        var dir = src_path.get_base_dir() + "/"
        var new_path = dir + new_name + ".json"
        if FileAccess.file_exists(new_path):
            push_warning("[LevelEditor] File already exists: " + new_path)
            return
        var src_data = _LoadJSON(src_path)
        if src_data.is_empty():
            return
        src_data["Name"] = new_name
        var json_text = JSON.stringify(src_data, "\t")
        var file = FileAccess.open(new_path, FileAccess.WRITE)
        if file:
            file.store_string(json_text)
            file.close()
            _RefreshLevelTree()
            _DoLoadLevel(new_path)
    )

    dialog.ok_button_text = "确定"
    add_child(dialog)
    dialog.popup_centered()
    dialog.tree_exited.connect(dialog.queue_free)

func _on_delete_level() -> void :
    var selected = level_tree.get_selected()
    if not selected or not selected.get_metadata(0):
        return
    var path: String = selected.get_metadata(0)
    var level_name = selected.get_text(0)

    var dialog = ConfirmationDialog.new()
    dialog.title = "删除关卡"
    dialog.dialog_text = "确定要删除关卡 \"%s\" 吗？\n此操作不可撤销。" % level_name
    dialog.confirmed.connect( func():
        DirAccess.remove_absolute(path)
        if current_level_path == path:
            current_level_path = ""
            current_level_data = {}
            edit_vbox.visible = false
            no_level_label.visible = true
            _dirty = false
            button_save.disabled = true
        _RefreshLevelTree()
    )
    dialog.ok_button_text = "删除"
    add_child(dialog)
    dialog.popup_centered()
    dialog.tree_exited.connect(dialog.queue_free)
