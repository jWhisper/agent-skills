# work-loop

`work-loop` 是一个给编程 agent 使用的自循环 harness skill。它的目标是减少长任务中的遗忘、走偏、幻觉式完成和依赖乱序。

它参考 long-running agent harness 的思路：先把环境和任务状态写进仓库文件，再让后续每个新对话从这些文件恢复，而不是依赖聊天记忆。

## 核心行为

当 agent 使用这个 skill 时，第一步必须自动检查当前项目目录，并创建缺失的 harness 文件：

- `CLAUDE.md`
- `AGENTS.md`
- `architecture.md`
- `task.json`
- `progress.md`
- `init.sh`
- `run-automation.sh`

如果文件已经存在，则跳过，不覆盖。

在 harness 初始化完成前，agent 不允许写业务代码。初始化后，agent 根据用户需求补全 `architecture.md` 和 `task.json`，然后列出任务概况给用户审核。只有用户明确说 `同意`、`执行`、`开始`、`approve`、`go ahead` 等批准语时，才进入任务执行。

## 工作流拆分

`work-loop` 把工作分成两条独立流程：

- 初始化/规划流程：创建或修复 harness 文件，按项目实际情况定制 `init.sh`，补全 `architecture.md` 和 `task.json`，然后等待用户审批。
- 任务执行流程：审批后才选择未阻塞任务，执行、验证、更新 `passes`、追加 `progress.md`，最后提交。

`init.sh` 属于初始化/环境恢复机制，不是每个任务的实现流程。它只负责检查当前项目真正需要的前置条件。

## 任务执行

`task.json` 是任务源。任务使用数字 ID，例如 `1`、`2`、`3`，并用 `depends_on` 表达依赖。任务不需要单独的 `status` 字段，完成状态只用 `passes` 判断。任务可以并且应该包含 `steps`，它表示完成该任务的子步骤；完成标准放在 `acceptance`，验证命令或人工检查放在 `verification`。依赖任务没有完成时，后续任务不能执行。

支持三种模式：

- `checkpoint`：只完成一个未阻塞任务，然后更新状态并停止。
- `continue`：连续执行未阻塞任务，直到完成、阻塞、验证失败或达到预算。
- `automation`：运行 `run-automation.sh`，通过外部循环反复启动新 agent 会话。

每个任务完成后，agent 必须：

1. 完成该任务的 steps，并通过 acceptance 和 verification。
2. 只把 `task.json` 中当前任务的 `passes` 改成 `true`。
3. 在 `progress.md` 追加 `task-complete` 记录，写明对应任务 ID、验证证据，以及成功/失败或阻塞/剩余/总任务数。
4. 重新读取 `task.json` 和 `progress.md`，确认两个文件都已更新。
5. 可用 git 时，再把业务改动、`task.json`、`progress.md` 作为一个任务提交。

没有同时更新 `task.json` 当前任务的 `passes` 和 `progress.md`，任务就不算完成，不能汇报完成，也不能进入下一个任务。
只有在 `task.json` 和 `progress.md` 都更新完成之后，才允许 commit；commit 必须把业务改动、`task.json`、`progress.md` 放在一起。

`progress.md` 只保留两种 entry：`task-complete` 和 `blocker`。每个 entry 都必须包含 `passed`、`failed_or_blocked`、`remaining`、`total` 四个计数。

## 新会话恢复

每次重启或新开对话时，agent 先读：

1. `CLAUDE.md` 或 `AGENTS.md`
2. `architecture.md`
3. `task.json`
4. `progress.md`

批准后，每个新会话和每个任务开始前都运行 `./init.sh`。它的作用是检查这个项目真正需要的前置条件，比如命令、文件、端口、模拟器、数据库或健康检查 URL，而不是看到 `package.json`、`go.mod`、iOS 工程等就自动安装依赖或启动服务。`init.sh` 应按项目实际情况定制。

## 安装 Skill

安装到 Codex 和 Claude Code：

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

如果已经安装过并需要替换：

```bash
bash work-loop/scripts/install-skill.sh --target all --mode symlink --force
```

## 手动初始化项目

正常情况下，agent 使用 skill 时会自动初始化。你也可以手动运行：

```bash
bash work-loop/scripts/setup-harness.sh --dir /path/to/project
```

覆盖已有 harness 文件需要显式传入：

```bash
bash work-loop/scripts/setup-harness.sh --dir /path/to/project --force
```

## 外部循环

计划批准后，可以启动外部循环：

```bash
./run-automation.sh --agent codex --tasks-per-run 3 --max-runs 8
./run-automation.sh --agent claude --tasks-per-run 3 --max-runs 8
```

如果某一轮没有任何任务从 `passes: false` 变成 `passes: true`，脚本会停止，避免空转。
