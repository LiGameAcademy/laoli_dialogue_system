extends Node
class_name PerformanceProfiler

## 性能分析器
## 用于测量代码执行时间，帮助定位性能瓶颈

## 性能数据（Key: 标签, Value: 开始时间戳）
var performance_data: Dictionary[String, int] = {}

## 性能统计（Key: 标签, Value: 统计信息字典）
var performance_stats: Dictionary[String, Dictionary] = {}

## 开始性能分析
## [param label] 分析标签（用于标识不同的性能测量点）
func start_profiling(label: String) -> void:
	performance_data[label] = Time.get_ticks_msec()

## 结束性能分析
## [param label] 分析标签
## [return] 耗时（毫秒）
func end_profiling(label: String) -> float:
	if not performance_data.has(label):
		push_warning("PerformanceProfiler: 未找到开始标记 '%s'" % label)
		return 0.0
	
	var start_time = performance_data[label]
	var end_time = Time.get_ticks_msec()
	var duration = float(end_time - start_time)
	
	performance_data.erase(label)
	
	# 更新统计信息
	if not performance_stats.has(label):
		performance_stats[label] = {
			"count": 0,
			"total_time": 0.0,
			"min_time": duration,
			"max_time": duration,
			"avg_time": 0.0
		}
	
	var stats = performance_stats[label]
	stats.count += 1
	stats.total_time += duration
	stats.min_time = min(stats.min_time, duration)
	stats.max_time = max(stats.max_time, duration)
	stats.avg_time = stats.total_time / float(stats.count)
	
	print("性能分析 [%s]: %.2f ms" % [label, duration])
	return duration

## 分析函数执行时间
## [param label] 分析标签
## [param func_to_profile] 要分析的函数（Callable）
func profile_function(label: String, func_to_profile: Callable) -> void:
	start_profiling(label)
	func_to_profile.call()
	end_profiling(label)

## 获取性能统计
## [param label] 分析标签（可选，如果为空则返回所有统计）
## [return] 统计信息字典
func get_stats(label: String = "") -> Dictionary:
	if label.is_empty():
		return performance_stats.duplicate()
	
	if performance_stats.has(label):
		return performance_stats[label].duplicate()
	
	return {}

## 清空所有统计数据
func clear_stats() -> void:
	performance_data.clear()
	performance_stats.clear()
	print("PerformanceProfiler: 统计数据已清空")

## 打印性能报告
## [param label] 分析标签（可选）
func print_report(label: String = "") -> void:
	var stats_to_print: Dictionary
	if label.is_empty():
		stats_to_print = performance_stats
	else:
		if performance_stats.has(label):
			stats_to_print[label] = performance_stats[label]
		else:
			push_warning("PerformanceProfiler: 未找到统计标签 '%s'" % label)
			return
	
	print("=== 性能分析报告 ===")
	for stat_label in stats_to_print:
		var stats = stats_to_print[stat_label]
		print("[%s]" % stat_label)
		print("  调用次数: %d" % stats.count)
		print("  总耗时: %.2f ms" % stats.total_time)
		print("  平均耗时: %.2f ms" % stats.avg_time)
		print("  最小耗时: %.2f ms" % stats.min_time)
		print("  最大耗时: %.2f ms" % stats.max_time)
	print("===================")

