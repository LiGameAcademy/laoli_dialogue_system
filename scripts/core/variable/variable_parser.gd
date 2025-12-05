class_name VariableParser

## 变量解析器（实例类）
## 负责解析并替换文本中的变量

## 变量管理器引用（用于获取变量值）
var variable_manager: VariableManager

## 条件变量解析器映射表（符合开闭原则：通过注册扩展功能）
var conditional_resolvers: Dictionary[String, ConditionalVariableResolver] = {}

## 预编译结果缓存（Key: 原始文本, Value: 预编译结果）
var precompile_cache: Dictionary[String, Dictionary] = {}

## 缓存大小限制
const MAX_CACHE_SIZE = 200

## 初始化
## [param manager] 变量管理器实例
func _init(manager: VariableManager) -> void:
	variable_manager = manager

## 注册条件变量解析器
## [param condition_type] 条件类型（如 "has_item"）
## [param resolver] 解析器实例
func register_conditional_resolver(condition_type: String, resolver: ConditionalVariableResolver) -> void:
	conditional_resolvers[condition_type] = resolver

## 解析并替换文本中的变量（带预编译缓存）
## [param text] 包含变量的文本（如："你好，{player_name}！"）
## [return] 替换后的文本
func parse_text(text: String) -> String:
	if text.is_empty():
		return text
	
	# 检查预编译缓存
	if precompile_cache.has(text):
		var precompiled = precompile_cache[text]
		return _apply_precompiled(precompiled)
	
	# 预编译文本
	var precompiled = precompile_text(text)
	
	# 添加到缓存（检查缓存大小）
	if precompile_cache.size() >= MAX_CACHE_SIZE:
		# 移除最旧的缓存（FIFO策略）
		var oldest_key = precompile_cache.keys()[0]
		precompile_cache.erase(oldest_key)
	
	precompile_cache[text] = precompiled
	
	# 应用预编译结果
	return _apply_precompiled(precompiled)

## 应用预编译结果
## [param precompiled] 预编译结果字典
## [return] 替换后的文本
func _apply_precompiled(precompiled: Dictionary) -> String:
	var text = precompiled.get("text", "")
	var variables = precompiled.get("variables", [])
	
	if variables.is_empty():
		return text
	
	var result = text
	
	# 从后往前替换（避免索引偏移问题）
	for i in range(variables.size() - 1, -1, -1):
		var var_info = variables[i]
		var var_name = var_info.get("var_name", "")
		var full_match = var_info.get("full_match", "")
		
		if full_match.is_empty():
			continue
		
		# 获取变量值
		var var_value = _get_variable_value(var_name)
		
		# 转换为字符串
		var value_str = _format_variable_value(var_value)
		
		# 替换文本
		result = result.replace(full_match, value_str)
	
	return result

## 预编译文本（提前解析变量位置）
## [param text] 原始文本
## [return] 预编译结果（包含变量位置信息）
func precompile_text(text: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	
	var matches = regex.search_all(text)
	var variables = []
	
	for match in matches:
		variables.append({
			"full_match": match.get_string(0),
			"var_name": match.get_string(1),
			"start": match.get_start(),
			"end": match.get_end()
		})
	
	return {
		"text": text,
		"variables": variables
	}

## 获取变量值（支持条件变量和普通变量）
## [param var_name] 变量名（可能包含条件，如 "has_item:sword"）
## [return] 变量值
func _get_variable_value(var_name: String) -> Variant:
	# 检查是否包含冒号（条件变量格式：condition:value）
	if ":" in var_name:
		var parts = var_name.split(":")
		if parts.size() == 2:
			var condition_type = parts[0]
			var value = parts[1]
			
			# 查找注册的解析器
			if conditional_resolvers.has(condition_type):
				var resolver = conditional_resolvers[condition_type]
				var result = resolver.resolve(condition_type, value)
				if result != null:
					return result
				# 解析器返回 null，表示不支持此类型
				push_warning("VariableParser: 条件变量解析器 '%s' 返回 null（可能不支持此条件类型）" % condition_type)
			else:
				push_warning("VariableParser: 未找到条件变量解析器 '%s'，变量名: '%s'" % [condition_type, var_name])
		else:
			push_warning("VariableParser: 条件变量格式错误 '%s'，应为 'type:value'（找到 %d 个部分）" % [var_name, parts.size()])
		# 条件变量解析失败，返回空字符串
		return ""
	
	# 普通变量或表达式
	return _parse_variable_expression(var_name)

## 解析变量名（可能包含表达式）
## [param var_name] 变量名或表达式（如 "player_level + 5"）
## [return] 解析后的值
func _parse_variable_expression(var_name: String) -> Variant:
	# 检查是否包含运算符
	if "+" in var_name or "-" in var_name or "*" in var_name or "/" in var_name:
		return _evaluate_expression(var_name)
	else:
		# 普通变量
		return variable_manager.get_variable(var_name, "")

## 计算简单表达式
## [param expression] 表达式字符串（如 "player_level + 5"）
## [return] 计算结果
func _evaluate_expression(expression: String) -> Variant:
	# 移除空格
	expression = expression.replace(" ", "")
	
	# 简单的表达式解析（支持 +, -, *, /）
	var operators = ["+", "-", "*", "/"]
	
	for op in operators:
		if op in expression:
			var parts = expression.split(op)
			if parts.size() == 2:
				var left = _parse_variable_value(parts[0])
				var right = _parse_variable_value(parts[1])
				
				if left is String or right is String:
					return ""  # 字符串不支持运算
				
				match op:
					"+":
						return left + right
					"-":
						return left - right
					"*":
						return left * right
					"/":
						if right != 0:
							return left / right
						return 0
	
	return ""

## 解析变量值（可能是变量名或数字）
## [param value_str] 值字符串
## [return] 解析后的值
func _parse_variable_value(value_str: String) -> Variant:
	# 尝试解析为数字
	if value_str.is_valid_int():
		return value_str.to_int()
	elif value_str.is_valid_float():
		return value_str.to_float()
	else:
		# 作为变量名
		return variable_manager.get_variable(value_str, 0)

## 格式化变量值
## [param value] 变量值
## [return] 格式化后的字符串
func _format_variable_value(value: Variant) -> String:
	if value == null:
		return ""
	
	match typeof(value):
		TYPE_STRING:
			return value
		TYPE_INT, TYPE_FLOAT:
			return str(value)
		TYPE_BOOL:
			return "是" if value else "否"
		TYPE_ARRAY:
			return str(value.size()) + "个"
		TYPE_DICTIONARY:
			return str(value.size()) + "项"
		_:
			return str(value)
