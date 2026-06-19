class_name NpcTalkControl extends Node2D

var npcTalkFeature

func AddNpc(npc: NpcBase) -> void :
    add_child(npc)

func ShowTalk(npc: NpcBase, talk: NpcTalkBaseConfig) -> void :
    npc.Talk(talk.text, talk.anime, talk.audio)

func ShowHand(npc: NpcBase, talk: NpcTalkHandConfig) -> void :
    npc.Hand(talk)
