# 剧情演出接入契约

状态：工作区开发版，2026-10-07。实际验证使用 Godot 4.7.2；4.5 兼容验证和正式插件版本发布尚未完成。

## 职责与安装

将插件放入 `res://addons/laoli_dialogue_system/`。CutscenePlayer 是局部场景，不新增 Autoload，也不查找玩家、相机或任务管理器。宿主连接步骤请求，执行自己的表现或开启对话，然后带运行编号与步骤编号回执。任务接取、开战、解锁等规则由宿主在终结事件中提交。

源插件保留文件缓存、历史、变量、主题、存档管理器及性能分析器。ARPG 内嵌的是较早版本，仅按相同会话契约迁移；没有整体覆盖或抹平两套版本差异。

默认 UI 使用 SystemFont，并且逐字音效默认不引用外部音频。需要音效时通过 DialogueTheme / AudioStreamPlayer 配置自己的素材。ARPG 的现有字体和声音配置保持原样。

## 配置与执行

- `CutsceneDefinition`：`cutscene_id`、`steps`、`skippable`，`validate()` 返回错误文字，步骤错误包含从 0 开始的索引。
- `CutsceneStep.PLAY_CLIP`：`clip_id` 非空，`timeout_seconds` 有限且大于 0。
- `SHOW_DIALOGUE`：`dialogue_id` 非空；没有自动阅读超时，由宿主明确结束或取消。
- `WAIT`：`duration_seconds` 有限且不小于 0；零时长仍经帧边界推进。

实例化 `scenes/cutscene_player/cutscene_player.tscn` 后调用 `play(definition)`。返回正整数表示本次运行；资源错误、忙碌、尚未进入场景树或正在退出时返回 -1。`last_error` 提供配置错误。

运行采用步骤的独立副本，外部修改原 Resource 不会改写本次等待条件。请求发出的步骤也是副本；宿主不要依赖对象身份匹配，应使用编号。

| 接口 / 信号 | 约定 |
| --- | --- |
| `step_requested(run_id, step_index, step)` | 宿主处理片段或对话；WAIT 由执行器推进 |
| `complete_step(run_id, step_index)` | 当前等待步骤完成；重复、过期、错误编号均忽略 |
| `fail_step(run_id, step_index, message)` | 当前步骤失败 |
| `abort(run_id, message)` | 当前环境失效；步骤间隙也允许失败 |
| `skip(run_id)` | 允许跳过时终结为 SKIPPED，不逐个执行被略过的片段 |
| `cancel(run_id, reason)` | 终结为 CANCELED，不提交规则 |
| `finished(run_id, cutscene_id, outcome)` | 每次运行最多一次，发信号前已清除运行状态 |
| `failed(run_id, step_index, message)` | FAILED 的诊断信号，在 finished 前发出；不要再提交规则 |
| `trace_event(run_id, step_index, event, detail)` | started / step_started / step_completed / finished，供宿主日志展示 |

移出场景树会取消正在运行的演出。执行器不承诺替宿主恢复镜头或释放输入锁：宿主必须消费终结事件并执行自己的清理。对象生命周期和业务有效性由宿主显式报告；执行器退出之后不能再启动。

## 对话会话

`start_dialogue_session(node_id)` 先预留编号，下一次延后调用才发出开始信号。忙碌或缺少入口节点返回 -1。`dialogue_session_started(session_id)` 后才发旧的 `dialogue_started`；开始回调中取消不会再发出迟到的旧开始信号。

UI 使用 `advance_dialogue_session`、`make_session_choice`、`cancel_dialogue_session`，并检查 `is_session_current`。按钮在创建时绑定对应会话，旧按钮不能选择新会话的选项；选项 Resource 还必须属于当前可用选项。

`dialogue_session_finished(session_id, reason)` 区分 COMPLETED / CANCELED / FAILED。宿主只推进自己持有的编号；取消自己的会话不能清理别人的对话。

旧的 `start_dialogue`、`process_node`、`make_choice` 和开始/结束信号保留，但旧启动接口也改为延后开始，调用后不要立即读取 current_node。推荐使用带编号接口。

通过 `set_initiator(node)` 显式注入玩家；宿主退出时 `clear_initiator(node)`。源插件仍支持 `register_player_getter`，但不再自动查找 Player 分组；未配置上下文时返回 null。动作与条件需要玩家时必须提供上下文。

## 完成、跳过与失败

完成和跳过应进入同一个宿主规则提交入口，并验证后置状态。跳过必须显式应用最终表现：例如 ARPG 入场设为完全异化后开战，收尾设为低异化后保留击败结果。不要在某段动画的回调里接任务或开放战斗。

取消与失败仅清理/恢复，不推进剧情标记。规则提交失败同样不启动战斗。演出完成标记由宿主持有，目前 ARPG 只保证单个关卡生命周期；跨读档的统一叙事快照属于下一阶段。

本次 ARPG 有两条资源：Boss 入场与击败后的回响收尾；共用执行器、会话桥接、镜头和退出清理。收尾取消不会撤销已经发生的击败事件，也不会复活 Boss。

## 验证

在独立测试宿主中安装本插件，配置 DialogueHistoryManager、VariableManager、QuestManager、DialogueManager 四个 Autoload。测试宿主不需要 ARPG、背包插件或外部字体、音效。命令如下：

```text
--headless --fixed-fps 60 --path <测试宿主目录> res://addons/laoli_dialogue_system/tests/verify_cutscene_contracts.tscn
--headless --fixed-fps 60 --path <测试宿主目录> res://addons/laoli_dialogue_system/tests/verify_plugin_compatibility.tscn
```

前者覆盖回执、忙碌、超时、取消、资源快照和执行器退出；后者覆盖默认 UI/主题、旧 getter/启动、变量/历史、缓存合并/卸载及过期会话。源插件更新测试宿主副本后重新验证；不要用 ARPG 的旧内嵌插件代替源仓兼容验证。

本轮在教程工作区 `.runtime/plugin_probe/` 构建并验证了这样的独立宿主。正式版本号、提交登记、编辑器启用/禁用完整旅程、存档读写及 4.5 验收仍需另行完成。
