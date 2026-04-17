#!/bin/sh
if [ -f ~/.claude/CLAUDE.md ]; then
  bat --color=always ~/.claude/CLAUDE.md
else
  echo "No CLAUDE.md found."
fi
