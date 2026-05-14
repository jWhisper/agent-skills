# 查看帮助

bash install-skill.sh --help

# 安装全部 skill 到 Codex + Claude，默认 symlink

bash install-skill.sh

# 只安装某个 skill

bash install-skill.sh --skill gold-miner

# 只安装到 Codex

bash install-skill.sh --target codex --skill gold-miner

# 用 copy 模式安装

bash install-skill.sh --target codex --skill gold-miner --mode copy

# 强制覆盖已有安装

bash install-skill.sh --skill gold-miner --force

# 卸载某个 skill

bash install-skill.sh --skill gold-miner --uninstall

# work-loop 专属：安装并初始化某个项目

bash install-skill.sh --skill work-loop --project /path/to/project
