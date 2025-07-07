# player.gd
extends Sprite2D

# 1. 将所有对话内容硬编码在一个数组里
var dialogue_lines = [
	"你好，冒险者。",
	"这个世界需要你的帮助。",
	"准备好出发了吗？"
]

# 2. 用一个变量来追踪当前说到第几句了
var current_line_index = 0

@onready var dialogue_label = $Label

func _ready():
	# 游戏开始时，先隐藏对话框
	dialogue_label.hide()

# 3. 监听全局输入事件
func _unhandled_input(event):
	# 当玩家按下"ui_accept"键 (通常是回车或空格)
	if event.is_action_pressed("ui_accept"):
		# 第一次按下时，开始对话
		if not dialogue_label.visible:
			dialogue_label.show()
			# 显示第一句对话
			dialogue_label.text = dialogue_lines[current_line_index]
			current_line_index += 1
			return
		
		# 如果对话还在进行中
		if current_line_index < dialogue_lines.size():
			# 显示下一句对话
			dialogue_label.text = dialogue_lines[current_line_index]
			current_line_index += 1
		else:
			# 对话已结束
			dialogue_label.hide()
			# 重置，以便下次可以重新开始对话
			current_line_index = 0
