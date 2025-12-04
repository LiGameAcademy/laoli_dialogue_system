# 随机对话与多文件管理功能更新日志

## 📅 更新日期
2024-12-04

## 🎯 新增功能

### 1. 随机文本对话系统

#### DialogueNode 扩展
- ✅ 新增 `text_keys: Array[String]` - 随机文本数组
- ✅ 新增 `text_weights: Array[float]` - 文本权重（加权随机）
- ✅ 新增 `last_selected_index: int` - 记录上次选择的索引（避免重复）
- ✅ 扩展 `get_text()` - 支持随机选择文本
- ✅ 实现 `_weighted_random_select()` - 加权随机选择
- ✅ 实现 `_non_repeating_random_select()` - 非重复随机选择

#### DialogueParser 扩展
- ✅ 支持解析文本数组格式
- ✅ 支持解析文本权重
- ✅ 支持多语言格式的数组项

### 2. 多文件管理系统

#### DialogueManager 扩展
- ✅ 新增 `loaded_files: Array[String]` - 已加载文件列表
- ✅ 扩展 `load_dialogue_file()` - 支持 `merge` 参数，防止重复加载
- ✅ 新增 `unload_dialogue_file()` - 卸载指定文件
- ✅ 新增 `clear_all_dialogues()` - 清空所有对话
- ✅ 新增 `reload_all_files()` - 重新加载所有文件
- ✅ 新增 `load_dialogue_if_needed()` - 按需加载（懒加载）

### 3. 闲聊系统

#### ChatterManager（新增）
- ✅ 实现 `try_trigger_chatter()` - 尝试触发闲聊（检查间隔）
- ✅ 实现 `force_trigger_chatter()` - 强制触发闲聊
- ✅ 实现时间间隔控制（默认30秒）
- ✅ 支持获取/设置最后闲聊时间

## 🔧 修改的文件

1. `scripts/core/dialogue/dialogue_node.gd` - 扩展随机文本支持
2. `scripts/core/dialogue/dialogue_parser.gd` - 扩展解析器支持文本数组
3. `scripts/core/dialogue/dialogue_manager.gd` - 扩展多文件管理
4. `scripts/core/chatter_manager.gd` - 新增闲聊管理器

## 📝 新增的文件

1. `scripts/core/chatter_manager.gd` - 闲聊管理器
2. `docs/random_chatter_system.md` - 使用文档
3. `docs/article_errors.md` - 文章错误检查报告
4. `examples/random_chatter_example.gd` - 使用示例
5. `examples/random_chatter_example.json` - JSON格式示例

## 🐛 修复的问题

### 从测试中发现并修复的代码问题

1. **action_factory.gd** - 修复 `register_action()` 中错误使用 `action.description` 应为 `action_type`
2. **game_state.gd** - 已使用 `item_resource.name`（无需修复）

## ⚠️ 文章中的错误（已修正）

1. **CHATTER_PREFIX 命名错误** - 改为 `CHATTER_SUFFIX`（实际是后缀）
2. **缺少重复加载检查** - 已添加
3. **缺少多语言数组支持** - 已添加
4. **range() 使用错误** - 已修正为循环追加
5. **缺少单例注册说明** - 已在文档中补充

## 📚 使用说明

### 基本使用

```gdscript
# 加载对话文件
DialogueManager.load_dialogue_file("res://data/dialogues/main_dialogue.json")

# 使用随机文本（JSON格式）
# {
#   "node_id": {
#     "character": "CHARACTER_NAME",
#     "text": ["TEXT_KEY_1", "TEXT_KEY_2", "TEXT_KEY_3"],
#     "next_node": "END"
#   }
# }

# 开始对话（会自动随机选择文本）
DialogueManager.start_dialogue("node_id")
```

### 多文件管理

```gdscript
# 加载多个文件
DialogueManager.load_dialogue_file("res://data/dialogues/main.json", true)
DialogueManager.load_dialogue_file("res://data/dialogues/village.json", true)

# 卸载文件
DialogueManager.unload_dialogue_file("res://data/dialogues/village.json")

# 清空所有
DialogueManager.clear_all_dialogues()
```

### 闲聊系统

```gdscript
# 注意：需要先注册 ChatterManager 为 AutoLoad 单例
# 或在 plugin.gd 中添加：
# add_autoload_singleton("ChatterManager", "scripts/core/chatter_manager.gd")

# 尝试触发闲聊
ChatterManager.try_trigger_chatter("npc_id")

# 强制触发
ChatterManager.force_trigger_chatter("npc_id")
```

## 🔄 向后兼容性

- ✅ 完全向后兼容：旧的单个文本格式仍然支持
- ✅ 如果节点只有 `text_key`，行为与之前完全相同
- ✅ 如果节点有 `text_keys` 数组，优先使用随机选择

## 📖 相关文档

- [随机对话系统文档](docs/random_chatter_system.md)
- [文章错误检查报告](docs/article_errors.md)
- [使用示例](examples/random_chatter_example.gd)

