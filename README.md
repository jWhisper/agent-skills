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

## 任务执行

`task.json` 是任务源。任务使用数字 ID，例如 `1`、`2`、`3`，并用 `depends_on` 表达依赖。依赖任务没有完成时，后续任务不能执行。

支持三种模式：

- `checkpoint`：只完成一个未阻塞任务，然后更新状态并停止。
- `continue`：连续执行未阻塞任务，直到完成、阻塞、验证失败或达到预算。
- `automation`：运行 `run-automation.sh`，通过外部循环反复启动新 agent 会话。

每个任务完成后，agent 必须：

1. 完成该任务的 steps、acceptance 和 verification。
2. 只把当前任务的 `passes` 改成 `true`。
3. 在 `progress.md` 追加本轮进度和验证证据。
4. 可用 git 时，把业务改动、`task.json`、`progress.md` 作为一个任务提交。

## 新会话恢复

每次重启或新开对话时，agent 先读：

1. `CLAUDE.md` 或 `AGENTS.md`
2. `architecture.md`
3. `task.json`
4. `progress.md`

批准后，每个新会话和每个任务开始前都运行 `./init.sh`，确保依赖、服务和本地状态可恢复。

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
