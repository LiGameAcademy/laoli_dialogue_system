@abstract
extends Resource
class_name GameAction 

## 可以在编辑器里给动作写备注
@export var description: String = ""

## 条件检查（如果条件不满足，则跳过此动作）
@export var condition: GameCondition = null

# 核心接口：执行动作（基类实现，包含条件检查）
# initiator: 谁发起了交互？(通常是 Player)
# target: 交互的对象是谁？(比如宝箱本身)
# [return] 是否成功执行（false 表示跳过，用于回退到下一个动作）
func execute(initiator: Node, target: Node) -> bool:
	# 检查条件（在基类中统一处理）
	if condition != null:
		if not condition.is_met(initiator, target):
			# 条件不满足，静默跳过
			return false
	
	# 条件满足或没有条件，执行具体动作逻辑
	return _execute_internal(initiator, target)

# 子类需要实现的具体执行逻辑
# initiator: 谁发起了交互？(通常是 Player)
# target: 交互的对象是谁？(比如宝箱本身)
# [return] 是否成功执行（false 表示跳过，用于回退到下一个动作）
@abstract func _execute_internal(initiator: Node, target: Node) -> bool

## 便捷方法：从JSON数据初始化GameAction实例
@abstract func init_from_data(action_data: Dictionary) -> void
