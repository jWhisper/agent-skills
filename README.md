# work-loop

`work-loop` 是一个轻量的长任务工作循环 skill，用来帮助 Codex 和 Claude Code 在同一个仓库里共享可恢复的编码流程。

它把复杂任务放进一个可恢复的节奏里：

1. 先读取仓库事实并写清楚方案。
2. 等用户批准计划。
3. 按 `task.json` 连续推进未完成任务。
4. 每轮先回归检查，再完成当前任务的 steps、acceptance、verification。
5. 通过后更新状态、记录进度，并留下可恢复的 handoff。

使用 skill 时，agent 应主动创建缺失的 Work Loop 文件，不需要用户先手动编写这些文件。批准前，它只能读仓库、生成或修改 `architecture.md`、`task.json`、`progress.md`、`init.sh`、`AGENTS.md`、`CLAUDE.md` 等规划/编排文件，不能运行 `init.sh`、安装依赖、启动服务或写业务代码。批准后，每个编码会话开始时应运行 `./init.sh`：它默认会安装依赖、准备本地状态，并在项目有 `dev` script 时启动开发服务器。缺少密钥、外部账号、付费服务、端口不可用或安装失败时，agent 应记录阻塞并停止。

## 目录

```text
work-loop/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── approval-gate.md
│   ├── automation.md
│   ├── execution-loop.md
│   ├── initializer.md
│   ├── progress-handoff.md
│   └── task-schema.md
└── scripts/
    ├── install-skill.sh
    ├── run-automation.sh
    └── setup-harness.sh
```

## 安装 Skill

同时安装到 Codex 和 Claude Code：

```bash
bash work-loop/scripts/install-skill.sh --target all --mode symlink
```

只安装到 Codex：

```bash
bash work-loop/scripts/install-skill.sh --target codex --mode symlink
```

只安装到 Claude Code：

```bash
bash work-loop/scripts/install-skill.sh --target claude --mode symlink
```

如果你想安装成独立副本，把 `--mode symlink` 换成 `--mode copy`。

安装脚本默认不会覆盖已有 `work-loop` skill。如需替换旧安装，添加 `--force`。

## 卸载 Skill

同时从 Codex 和 Claude Code 卸载：

```bash
bash work-loop/scripts/install-skill.sh --uninstall --target all
```

只从 Codex 卸载：

```bash
bash work-loop/scripts/install-skill.sh --uninstall --target codex
```

只从 Claude Code 卸载：

```bash
bash work-loop/scripts/install-skill.sh --uninstall --target claude
```

等价的手动方式是删除对应目录：

```bash
rm -rf ~/.codex/skills/work-loop
rm -rf ~/.claude/skills/work-loop
```

卸载只会移除安装到 agent skill 目录里的 `work-loop`，不会删除这个仓库，也不会删除已经在目标项目里生成的 `architecture.md`、`task.json`、`progress.md`、`init.sh`、`run-automation.sh`、`AGENTS.md` 或 `CLAUDE.md`。

## 初始化项目

在目标项目中创建 Work Loop 编排文件：

```bash
bash work-loop/scripts/setup-harness.sh /path/to/project
```

脚本会生成缺失的：

- `architecture.md`
- `task.json`
- `progress.md`
- `init.sh`
- `run-automation.sh`
- `AGENTS.md`
- `CLAUDE.md`

默认不会覆盖已有文件。如需覆盖，使用：

```bash
bash work-loop/scripts/setup-harness.sh --force /path/to/project
```

## 任务格式

`task.json` 的最小结构：

```json
{
  "project": "Project name",
  "description": "Short project goal",
  "approval": {
    "status": "pending",
    "approved_by": "",
    "approved_at": ""
  },
  "execution": {
    "default_mode_after_approval": "continuous"
  },
  "tasks": [
    {
      "id": 1,
      "title": "New chat",
      "category": "functional",
      "description": "New chat button creates a fresh conversation",
      "depends_on": [],
      "steps": [
        "Navigate to main interface",
        "Click the 'New Chat' button",
        "Verify a new conversation is created",
        "Check that chat area shows welcome state",
        "Verify conversation appears in sidebar"
      ],
      "acceptance": [
        "All listed steps pass in the running app",
        "No related previously-passing chat behavior regresses"
      ],
      "verification": [
        "Run the relevant lint/build/test command",
        "For UI changes, verify the flow in a browser and check for console errors"
      ],
      "passes": false
    }
  ]
}
```

`approval.status` 为 `pending` 时，只规划不实现。用户批准后再按 `execution.default_mode_after_approval` 推进任务。每个任务必须有唯一稳定的数字 `id`，推荐使用 `1`、`2`、`3` 这种顺序编号，方便表达第几步、依赖关系、进度日志和提交信息。每个任务通过 `depends_on` 声明依赖关系，通过 `steps` 描述操作步骤，通过 `acceptance` 定义完成标准，通过 `verification` 定义必须执行的检查。

任务选择规则是：只选择第一个 `passes: false` 且所有 `depends_on` 任务都已经 `passes: true` 的任务。这样 API、数据模型、认证、UI 等有依赖的任务不会乱序执行。

## 执行模式

`execution.default_mode_after_approval` 支持：

- `checkpoint`：只完成一个未阻塞任务，然后更新进度并停止。
- `continuous`：持续推进任务，直到全部完成、遇到阻塞、发现回归或达到任务预算。
- `automation-loop`：交给 `run-automation.sh` 启动多轮新会话并写入日志。建议至少手动跑通一个任务后再使用。

`continuous` 模式下，成功完成一个任务后不应询问“是否继续下一个任务”，而是自动选择下一个未阻塞任务，直到出现停止条件。

## 新会话恢复

重开 Claude Code 或 Codex 会话后，agent 应先读这些文件，再继续任务：

1. `CLAUDE.md` 或 `AGENTS.md`
2. `architecture.md`
3. `task.json`
4. `progress.md`

不要依赖之前聊天上下文。上一轮必须把必要信息写进 `progress.md`，新会话从这些文件恢复状态。

## 批准门

`work-loop` 采用明确的批准门：

1. 你描述需求。
2. Agent 只生成或更新 `architecture.md`、`task.json`、`progress.md` 和项目指令文件。
3. 你 review 计划。
4. 你明确回复 `approve`、`go ahead`、`LGTM`、`批准` 或 `同意执行`。
5. Agent 才把 `approval.status` 改成 `approved`，运行 `init.sh`，并进入逐任务执行循环。

批准前禁止：

- 运行 `./init.sh`
- 安装依赖
- 启动开发服务器
- 修改业务代码
- 执行 `task.json` 中的任务
- 把任务标记为 `passes: true`
- 运行 `run-automation.sh`

批准后，任务定义默认冻结。正常执行时不要改 `id`、`title`、`description`、`depends_on`、`steps`、`acceptance`、`verification`，只更新 `passes` 和 `progress.md`。如果任务拆分本身错了，应先停下来重新规划。

## 进度与阻塞记录

完成任务后，在 `progress.md` 追加：

```markdown
## Session N - Task: task-id

### What changed
- Files or areas changed.

### Steps
- [x] Step that was completed.

### Acceptance
- [x] Acceptance result and evidence.

### Verification
- Command, manual check, screenshot, or reason a check was not applicable.

### Issues
- None, or the issue and how it was resolved.

### Next
- Next unblocked task, remaining blocker, or completion state.
```

遇到阻塞时，在 `progress.md` 追加：

```markdown
## Session N - BLOCKED: task-id

### Blocker
- Exact blocker and where it occurred.

### What was completed
- Any safe partial work that remains.

### What is needed
- Specific human action, credential, decision, or environment repair.

### Resume instructions
- What the next session should do after the blocker is resolved.
```

每轮结束前检查：

- build/test 已运行，或无法运行的原因已记录
- `task.json` 状态准确
- `progress.md` 已写当前 session
- 可提交时保持一个任务一个提交
- 工作区干净，或剩余改动已说明

## 环境初始化逻辑

生成的 `init.sh` 会主动执行常见项目的 bootstrap：

- Node 项目：根据 lockfile 选择 `pnpm install`、`yarn install` 或 `npm install`，如果存在 `dev` script，则后台启动开发服务器。
- Rust 项目：运行 `cargo fetch`。
- Go 项目：运行 `go mod download`。
- Python 项目：保留项目专用命令占位，因为 Python 工具链差异较大。

这套逻辑服务于长任务工作循环：每个批准后的新会话先恢复可运行环境，再选择下一个未完成任务。

## 权限与自动化模式

计划被用户批准后，安装依赖和启动本地开发服务器属于正常执行流程，agent 应通过 `./init.sh` 主动完成，而不是要求用户手动做。只有遇到密钥、外部账号、付费服务、缺失工具、网络受限或系统级权限时才停止并记录阻塞。

外层无人值守循环应由操作者显式启动。常见模式是：

```bash
# Codex: workspace-write sandbox, no per-command approval prompts
codex exec -a never -s workspace-write

# Claude Code: explicitly skip interactive permission prompts
claude -p --dangerously-skip-permissions
```

交互式会话仍应遵守当前工具环境的权限提示。

## 可选外层循环

`run-automation.sh` 会被复制到目标项目，但默认不会自动运行。你暂时不用它也没关系。

当 `task.json` 已经通过人工审核，并且 `approval.status` 是 `approved` 时，可以手动启动：

```bash
./run-automation.sh --agent codex --tasks-per-run 3 --max-runs 10
./run-automation.sh --agent claude --tasks-per-run 3 --max-runs 10
```

它会反复启动新的 Codex/Claude 会话，每轮最多推进指定数量的任务。如果某一轮没有任何任务从 `passes: false` 变成 `passes: true`，脚本会停止并让你查看日志。
