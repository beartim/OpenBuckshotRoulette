# v6：修复 iOS 中文显示为方框

- 复用项目已有的简体中文 `NotoSansSC` 与繁体中文 `NotoSansTC` 字体。
- 构建时自动生成 `scripts/IOSFontFallback.gd` 并注册为 Autoload。
- 为所有已加载的 `Font`、Theme 字体、字体覆盖、LabelSettings、Label3D/TextMesh 字体追加中文字形 fallback。
- 根据当前语言自动调整简体/繁体字体优先级。
- 在嵌入字体之后追加 iOS `PingFang SC/TC` 系统字体兜底。
- 新场景节点加入 SceneTree 时也会立即补上 fallback，避免后续界面再次出现方框。
- 语言切换后自动重建 fallback 顺序。
- CI 在导入阶段检查 fallback 脚本解析错误，并保存 `cjk-font-fallback-check.txt`。

根因不是翻译缺失，而是游戏原有拉丁字体没有配置中文 glyph fallback。桌面系统可能自动回退到系统中文字体，iOS 上自定义 FontFile 不应依赖这种隐式行为。
