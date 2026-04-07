vscode_claude/qtcreator/.github/
├── copilot-instructions.md          ← 全局规则（每次对话自动生效）
├── instructions/
│   ├── report-format.instructions.md  ← 报告文件格式规范（写报告时自动应用）
│   └── source-code.instructions.md    ← 源码修改规范（改代码时自动应用）
├── prompts/
│   ├── audit-compat.prompt.md         ← /audit-compat 兼容性审计命令
│   ├── framework-report.prompt.md     ← /framework-report 架构分析命令
│   └── downgrade-exec.prompt.md       ← /downgrade-exec 降级改造命令
└── agents/
    ├── code-auditor.agent.md          ← @code-auditor 审计专家（只读分析）
    └── code-modifier.agent.md         ← @code-modifier 改造执行者（实际改码）