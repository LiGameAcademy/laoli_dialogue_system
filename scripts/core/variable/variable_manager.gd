extends Node

const CACHE_DURATION = 1.0  # 缓存持续时间（秒）

## 变量存储字典
## Key: 变量名, Value: 变量值（可以是String、int、float、bool）
var variables: Dictionary[String, Variant] = {}

## 变量提供者列表（用于从不同系统获取变量）
var variable_providers: Array[Callable] = []

## 变量缓存（避免重复计算）
var variable_cache: Dictionary[String, Variant] = {}
var cache_timestamp: Dictionary[String, float] = {}

## 变量解析器（实例）
var parser: VariableParser = VariableParser.new(self)

## 注册默认的条件变量解析器（在 _ready 中注册，确保所有系统都已初始化）
func _ready() -> void:
	# 注册默认的条件变量解析器
	_register_default_resolvers()

## 注册变量提供者
## [param provider] 提供变量的函数（返回Dictionary[String, Variant]）
func register_variable_provider(provider: Callable) -> void:
	variable_providers.append(provider)

## 设置变量值
## [param name] 变量名
## [param value] 变量值
func set_variable(name: String, value: Variant) -> void:
	variables[name] = value

## 获取变量值
## [param name] 变量名
## [param default] 默认值（如果变量不存在）
## [return] 变量值
func get_variable(name: String, default: Variant = null) -> Variant:
	# 首先从本地变量中查找
	if variables.has(name):
		return variables[name]
	
	# 从变量提供者中查找
	for provider in variable_providers:
		var provider_vars = provider.call()
		if provider_vars.has(name):
			return provider_vars[name]
	
	# 返回默认值
	return default

## 获取所有变量（包括提供者的变量）
## [return] 所有变量的字典
func get_all_variables() -> Dictionary:
	var all_vars = variables.duplicate()
	
	# 合并提供者的变量
	for provider in variable_providers:
		var provider_vars = provider.call()
		all_vars.merge(provider_vars, true)
	
	return all_vars

## 获取变量值（带缓存）
func get_variable_cached(name: String, default: Variant = null) -> Variant:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 检查缓存
	if variable_cache.has(name):
		var timestamp = cache_timestamp.get(name, 0.0)
		if current_time - timestamp < CACHE_DURATION:
			return variable_cache[name]
	
	# 获取新值
	var value = get_variable(name, default)
	
	# 更新缓存
	variable_cache[name] = value
	cache_timestamp[name] = current_time
	
	return value

## 注册默认的条件变量解析器
func _register_default_resolvers() -> void:
	# 注册物品解析器
	var item_resolver = ItemResolver.new()
	parser.register_conditional_resolver("has_item", item_resolver)
	
	# 注册任务解析器（支持 has_quest 和 quest_status）
	var quest_resolver = QuestResolver.new()
	parser.register_conditional_resolver("has_quest", quest_resolver)
	parser.register_conditional_resolver("quest_status", quest_resolver)
