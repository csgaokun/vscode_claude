# Qt Creator 4.13.3 插件裁剪记录 001 - StudioWelcome

## 1. 记录信息

- 记录编号：001
- 记录日期：2026-04-08
- 裁剪对象：StudioWelcome
- 裁剪级别：方案 B，构建级裁剪
- 裁剪状态：已落源码，待后续重生构建验证

## 2. 裁剪目标

本次裁剪目标是把 StudioWelcome 从 Qt Creator 4.13.3 的正式插件构建入口中移除，使其不再参与后续 qmake 子树生成、编译和安装打包。

本次不做的事情：

- 不删除 `src/plugins/studiowelcome/` 源码目录
- 不修改标准 `welcome` 插件
- 不做源码级彻底清扫

这样可以把风险控制在最小范围，同时保留后续回滚空间。

## 3. 裁剪原因

依据前置分析报告 [qt-creator-4.13.3-studiowelcome-plugin-report.md](qt-creator-4.13.3-studiowelcome-plugin-report.md)，StudioWelcome 的性质是：

- Qt Design Studio 风格欢迎页插件
- 默认禁用
- 无其他插件对它的源码级反向依赖
- 使用与标准 `welcome` 相同的 Welcome 模式位，只是替换默认欢迎页体验

因此，对普通 Qt Creator 目标而言，它属于可裁剪插件。

本次选择方案 B 的原因：

- 比源码级彻底删除更安全
- 比仅依赖 `DisabledByDefault` 更彻底
- 能直接减少后续构建和打包负担

## 4. 实施内容

### 4.1 修改文件

本次仅修改 1 个正式构建入口文件：

- `src/plugins/plugins.pro`

### 4.2 修改动作

从 `SUBDIRS` 中移除：

- `studiowelcome`

### 4.3 预期效果

在后续重新执行 qmake 和编译后，预期结果为：

- `src/plugins/studiowelcome` 不再参与插件子树构建
- 不再生成 `StudioWelcome4.dll`
- 不再安装到最终 `lib/qtcreator/plugins/` 目录

## 5. 影响评估

### 5.1 保留不变的部分

- 标准 `welcome` 插件仍保留
- Qt Creator 的 Welcome 模式概念仍保留
- 工程打开、编辑、构建、调试、项目管理等主链不应直接受影响

### 5.2 被移除的能力

在后续重建产物后，将失去：

- Qt Design Studio 风格欢迎页
- Studio 风格启动 splash screen
- StudioWelcome 提供的 Examples / Tutorials / Blog / Community 入口页
- 该插件所做的全局字体替换
- 该插件所做的 `qtdesignstudio.qch` / `qtquick.qch` / `qtquickcontrols.qch` 注册路径

### 5.3 风险级别

- 风险等级：低
- 风险来源：主要在 UI/欢迎页层，不在 IDE 主功能链

## 6. 当前验证状态

本次已完成：

- 已在源码正式入口中移除 `studiowelcome`
- 已保留完整源码目录，便于回滚和二次评估
- 已形成单独裁剪记录，便于后续累计插件裁剪工作

本次尚未完成：

- 尚未重新 qmake 生成插件子树 Makefile
- 尚未重新编译并确认 `StudioWelcome4.dll` 消失
- 尚未做欢迎页启动回归

原因：

- 本次先落正式源码侧改动与记录文件，后续可把多项插件裁剪合并到一轮构建回归中做统一验证

## 7. 回滚方式

若需回滚本次裁剪：

1. 在 `src/plugins/plugins.pro` 中把 `studiowelcome` 加回 `SUBDIRS`
2. 重新 qmake 生成插件子树 Makefile
3. 重新编译 Qt Creator 插件子树

由于本次未删除 `src/plugins/studiowelcome/` 目录，回滚成本很低。

## 8. 后续建议

建议后续所有插件裁剪记录统一采用相同格式，并保持编号递增，例如：

- `plugin-trim-record-002-<plugin>.md`
- `plugin-trim-record-003-<plugin>.md`

这样后续可以形成一组连续的插件裁剪台账，方便：

- 回顾每次裁剪范围
- 追踪风险与回滚方式
- 规划多插件合并构建回归

## 9. 下一步建议

本次裁剪落地后，下一步最合理的是：

1. 继续筛下一批可裁剪插件，累计到若干项后统一做一轮 qmake + 编译 + 启动回归
2. 或者立即对本次裁剪单独做一轮插件子树重生与构建验证，确认 `StudioWelcome4.dll` 不再产出