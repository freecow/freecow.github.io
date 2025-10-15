---
aliases: 
tags: 
date_modified: 
date: 2025-10-7
---

# Alias汇总

## tmux快速切换

命令格式：t <session-name>

```bash
t() {
    if [ "$1" = "list" ]; then
        tmux list-sessions
    else
        session_name="$1"
        if tmux has-session -t "$session_name" 2>/dev/null; then
            tmux attach-session -t "$session_name"
        else
            tmux new-session -s "$session_name"
        fi
    fi
}
```

## conda快速切换

命令格式：c <env-name>

```bash
c() {
    case "$1" in
        list)
            shift
            conda env list "$@"
            ;;
        *)
            conda activate "$1"
            ;;
    esac
}
```

