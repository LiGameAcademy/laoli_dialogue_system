# 插件使用说明

## 安装

插件根目录放在 res://addons/laoli_dialogue_system/，推荐子模块固定版本。启用后重新打开工程。当前验证 Godot 4.7.2，不宣称 4.5 已验证。

完整插件登记 DialogueHistoryManager、VariableManager、QuestManager、DialogueManager。宿主已有同名单例会保留；应先解决同名不同实现的冲突。默认 UI 使用系统字体，不要求外部音频素材。

## 对话与任务

用 DialogueNode / DialogueOption Resource 或 JSON 配置对话。加载文件后开始会话，通过 set_initiator 显式传入交互者；自定义 UI 用带编号的推进、选择和取消接口，避免旧回调影响新会话。

宿主向 QuestManager 注册游戏事件、任务数据库查询和配置资源查询。任务配置只读，接取后独立保存进度。目标完成进入可交付状态，交付、奖励和世界变化由宿主负责。见[配置示例](installation.md)。

## 剧情演出

实例化 CutscenePlayer 并提供 CutsceneDefinition。PLAY_CLIP 和 SHOW_DIALOGUE 由宿主完成后按运行编号、步骤编号回执；WAIT 自动推进。完成或跳过可提交预期结果；取消和失败只清理表现、会话与控制锁。

四文件核心无需完整插件服务。执行器不查找玩家、相机或任务，不包含具体 ARPG 片段。完整参数和回执时序见[演出契约](cutscenes.md)。

## 检查点

CheckpointStore 存储 JSON；QuestSnapshot 先准备独立任务实例；全部数据验证通过后再安装。历史快照保留节点、说话者和文本，不保留完整选项记录与时间戳。宿主定义版本、剧情标记、保存时机和角色恢复；检查点不是完整背包或角色存档。

## 排错与升级

检查目录嵌套、单例冲突和首次启用后是否重启。旧 validata() 改为 validate()，旧 transcript 改用历史服务接口。先验证并发布插件，再更新宿主子模块指针。运行 python tools/run_tests.py --godot <Godot路径> 验证独立插件，宿主还需验证自己的剧情、UI 与输入。

本目录只提供插件使用说明，不包含逐课教程、录制稿与游戏跟做内容。
