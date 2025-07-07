# player.gd
extends Sprite2D

@onready var dialogue_label = $Label

func _ready():
	# 游戏开始时，先隐藏对话框
	dialogue_label.hide()

# 监听全局输入事件
func _unhandled_input(event):
	# 当玩家按下"ui_accept"键 (通常是回车或空格)
	if event.is_action_pressed("ui_accept"):
		# 直接通过全局名称调用DialogueManager
		# 我们把要开始的对话ID作为参数传进去
		DialogueManager.start_dialogue("village_chief_start")
