## 条件变量解析器接口
## 用于解析条件变量（如 {has_item:sword}）
## 符合开闭原则：通过注册新的解析器来扩展功能，无需修改核心代码
class_name ConditionalVariableResolver

## 解析条件变量
## [param condition_type] 条件类型（如 "has_item"）
## [param value] 条件值（如 "sword"）
## [return] 解析后的值（通常是字符串）
func resolve(condition_type: String, value: String) -> Variant:
	return ""
