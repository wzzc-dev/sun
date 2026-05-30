# wzzc-dev 开发路线图

## 项目概述

wzzc-dev 是一个 MoonBit 语言的 2D 图形与文本渲染库，包含以下核心模块：
- **graphics** - 2D 图形渲染
- **text** - 文本处理与字体渲染
- **renderer** - graphics 与 text 的组合渲染层
- **softbuffer** - 窗口管理与像素显示

## 中长期目标

把 sun 打造成一个 MoonBit 原生、CPU 优先、可测试、跨平台的轻量 2D
渲染栈，重点服务文本渲染、矢量图形、像素输出和 GUI 基础设施。

更具体地说，sun 的中长期形态不是一个只会画 demo 的窗口库，而是一套
可以被 GUI、文档编辑器、图表、小游戏和 headless 渲染工具复用的基础渲染层：

- 对上提供稳定的 `Canvas`、`Path`、`Paint`、`Pixmap`、`TextLayout`、`Renderer`
  API，让应用层用 MoonBit 类型直接描述要画什么。
- 对中间层保持确定性的 CPU 渲染核心，包括路径填充/描边、glyph raster、mask
  composition、image blit、clip、transform 和 alpha blending。
- 对下通过 `Surface`/present 契约接入 native window、内存 surface、WASM canvas
  和未来的 GPU backend，让渲染结果可以显示、测试或离屏导出。
- 以可回归测试为长期护栏：像素级、mask 级、字体解析级、layout 级和 build-only
  backend 验证都要能在本地一条命令跑通。

### 目标定位

sun 的目标用户是需要在 MoonBit 中直接构建 GUI、编辑器、图表、小游戏或离屏渲染工具的开发者。它应该先成为一套“小而可靠”的基础设施：公共 API 清楚、像素结果确定、跨包边界明确、后端可以替换，而不是一开始就追求大型工业渲染引擎的完整功能面。

中长期成功标准：

- **可组合**：应用层可以只依赖 `graphics` 做 headless 绘制，也可以通过 `renderer` 接入文本，再通过 `softbuffer` 或后续后端显示到窗口。
- **可测试**：核心行为能用单元测试、像素断言、coverage dump、`.mbti` diff 和 build-only 后端检查稳定验证。
- **可演进**：`Font`、`Canvas`、`Surface`、`LayerTree`、`RenderFrame` 等类型有清晰职责，内部算法替换不破坏上层使用方式。
- **可落地**：至少一个真实窗口示例、一个 headless 渲染示例和一组 benchmark 能长期跟随代码演进。

### 非目标

- 短期内不追求 Skia/Cairo 级完整特性，也不把 GPU 作为正确性的前提。
- 不把 `graphics` 绑定到字体解析或窗口系统；文本和 present 通过独立包组合。
- 不优先支持所有 OpenType 高级能力；先把 TTF、Latin/ASCII、基础 CJK 和常见 GUI
  文本场景打稳。
- 不让平台后端决定公共 API 形状；后端差异应被封装在 `softbuffer` 或后续 backend
  adapter 中。

### 设计原则

- **MoonBit 原生 API**：优先提供清晰、稳定、符合 MoonBit 习惯的类型和方法，而不是照搬某个 C/C++ 渲染库的接口。
- **CPU 软件渲染优先**：先保证像素结果确定、可测试、可移植；GPU/WebGPU 作为长期优化方向，不作为早期正确性的前提。
- **文本是一等能力**：字体解析、glyph run、baseline、layout、raster mask 和 Canvas 绘制需要形成一条真实链路。
- **渲染结果可回归**：核心算法必须能通过单元测试、快照测试、build-only 后端测试持续验证。
- **后端可替换**：窗口、surface、present、event loop 与渲染核心解耦，方便 Win32、Wayland、AppKit、WASM 等后端逐步落地。

### 目标架构

```text
Application / GUI
  -> Canvas / TextLayout / Path API
  -> Renderer Core
  -> Path Rasterizer + Glyph Rasterizer + Image Blitter
  -> Pixmap / Surface
  -> Backend: Win32 / Wayland / AppKit / WASM
```

### 验证基线

根目录使用 `scripts/check_ci.sh` 作为本地验证入口。它执行纯渲染包的可执行测试，并对 GUI/window 后端执行 build-only 验证，避免当前 MoonBit native runner 在 macOS AppKit framework 链接上的已知限制影响日常开发。

每个能影响公共 API 或像素结果的改动，都应该至少说明：

- `moon info` 后 `.mbti` 是否发生预期变化。
- 相关包的 `moon test` 是否通过。
- `scripts/check_ci.sh` 是否通过，或为什么只跑了更窄的验证。
- 如果改动像素输出，是否新增/更新了可读的像素或 coverage mask 回归。

### 分层边界

| 层级 | 当前包 | 职责 | 边界约束 |
|------|--------|------|----------|
| Drawing Core | `graphics` | `Color`、`Pixmap`、`Canvas`、`Path`、`Paint`、clip、transform、fill/stroke、mask/image composition、`Surface` trait | 不依赖字体解析和窗口系统 |
| Text Core | `text` | TTF parsing、glyph outline、layout、kerning、raster mask、Unicode line break 基础 | 不直接依赖 `graphics` |
| Composition | `renderer` | 把 `text.CoverageMask` 组合到 `graphics.Canvas`，提供真实文本绘制入口 | 保持薄层，避免重复图形或字体逻辑 |
| Presentation | `softbuffer` | native window handle、`NativeSurface`、present pixels、event loop glue | 只适配后端，不承载渲染算法 |
| Examples/GUI | `examples` 和后续 GUI 包 | 验证真实使用方式和跨包 API ergonomics | 示例应走公开 API，不绕内部实现 |

### 长期能力矩阵

| 能力域 | v0.2 可用基线 | v0.5 稳定目标 | v1.0-alpha 目标 |
|--------|---------------|---------------|-----------------|
| Text | TTF -> layout -> glyph mask -> Canvas，Latin/ASCII 回归，`TextLayout` 基础对齐、显式换行、尾随空格和 spacing | 明确 `FontFace`/`GlyphRun`/`TextLayout` API，基础 CJK、kerning、fallback 轮廓 | Unicode 分段、BiDi 初版、字体缓存、更多 OpenType 表 |
| Vector | transform-aware rect/path fill、line/polyline/polygon/arc/pie/rect/circle/ellipse/uniform 与 per-corner rounded-rect Canvas helpers、stroke、cap/join/dash、clip/intersect clip、transform helpers、Canvas save/restore state stack、4x4 coverage | 更稳定的 fill rule、miter/dash 行为、路径简化和基础 boolean 可评估 | 文档化 Canvas API、复杂路径回归、性能基准 |
| Image/Layer | Pixmap blit、source-rect atlas drawing、tiled Pixmap fills、nearest/bilinear/bicubic sampling modes、fast/balanced/high quality strategy、transform-aware sampled Pixmap drawing、nine-patch GUI image scaling、`Paint` blend modes、dirty region 合并、mask/alpha composition、Layer cache、LayerTree、属性变化 invalidation、LayerTree partial present、RenderFrame resize、rect present API | GUI event-loop 调度与 layer lifecycle 策略 | PNG 基础解码、GUI 集成 |
| Surface | `MemorySurface`、`NativeSurface`、`Canvas/Pixmap::present_to`、`RenderFrame -> NativeSurface` helpers、`present_pixels_rect` | dirty rect 调度、row stride、错误传播和 pre-present hook 标准化 | Win32/macOS/Linux/WASM 后端都有 build 或运行验证 |
| Tooling | `scripts/check_ci.sh`、`.mbti`、核心单测、headless render smoke test、deterministic render bench smoke | warning baseline 可审查、覆盖率/benchmark 初版 | release checklist、示例矩阵、性能趋势 |

### 中期工作主线

1. **稳定 public API 边界**：优先收敛 `FontFace`、`GlyphRun`、`TextLayout`、`Renderer`、`Surface`、`RenderFrame` 的职责；任何 `.mbti` 变化都应说明动机。
2. **扩大真实输入覆盖**：用真实 TTF fixture、ASCII glyph matrix、kerning、复合 glyph 和后续 CJK fallback 验证文本链路。
3. **打磨 CPU 渲染质量**：保留确定性 4x4 coverage 基线，同时评估更高质量 coverage、image sampling 和 path/stroke 边界行为。
4. **把 dirty rendering 接入事件循环**：让 `LayerTree` 与 `RenderFrame` 的 dirty rect 能驱动窗口 redraw/present，而不是只在示例里手动调用。
5. **建立工程质量门槛**：warning baseline、coverage、benchmark、示例矩阵和发布 checklist 都应成为日常维护资产。

---

## 当前状态评估

### ✅ 已完成
- 工作区基础验证入口：`scripts/check_ci.sh`
- graphics/text 可执行单元测试
- GUI/window 后端 build-only 验证策略
- `headless_render` 示例走 `RenderFrame + LayerTree + MemorySurface`，无需窗口即可自校验离屏渲染与 dirty present 路径
- `graphics.validate_present_rect` 标准化 Surface rect present 的 bounds、row stride 和 buffer 长度校验，`MemorySurface` 与 `softbuffer.NativeSurface` 共享同一错误语义
- `MemorySurface` 记录每次 validated present 的目标 rect、row stride 与聚合像素/字节 telemetry，让 headless 测试能直接审查 present lifecycle
- `PresentRectPayload`/`PresentBatch` 将 dirty present plan 物化为 packed rect payload，复用同一批量提交与成本统计语义
- `Canvas::dirty_present_batch` 支持提交前 dry-run packed rect batch，不触发 present、不清 dirty，供事件循环做批量调度
- `LayerTree`/`RenderFrame` 支持提交前 dry-run dirty present batch，临时合成 layer 脏区后恢复 target 像素和 dirty 状态
- `DirtyRegion::present_plan` 将 dirty present 策略显式化为 Empty/Rects/Bounds，作为批量提交和事件循环调度的可测试基础
- `Canvas::dirty_present_plan` 让提交前可查询同一份 dirty present plan，`Canvas::present_dirty_to_with_limit` 也按该 plan 执行提交
- `LayerTree` 与 `RenderFrame` 暴露 dirty present plan 查询，合并 canvas 与 layer dirty 区域后再按统一计划提交
- `DirtySubmitPlan` 将逻辑 dirty bounds 与裁剪后的 present plan 合成可测试快照，供事件循环区分 dirty、present 与 clipped-away dirty 状态
- `DirtySubmitState` 将 Clean/Present/DirtyClippedAway 调度状态显式化，减少事件循环侧组合判断
- `DirtySubmitResult` 与 `RenderFrame::submit_dirty_to` 将调度状态和实际 present rect 数合成提交结果，供事件循环直接消费
- `DirtySubmitResult` 暴露 needs-present、clipped-away、dirty bounds 与 fallback 等直达查询，减少事件循环继续拆 plan
- `DirtySubmitResult` 暴露 did-present 事实查询，把提交前计划判断和提交后像素送达判断分开
- `DirtyPresentPlan`/`DirtySubmitPlan`/`DirtySubmitResult` 暴露计划提交像素数与紧凑 RGBA 字节数，给事件循环提供可测试的 present 成本预算
- dirty present/submit/result 暴露相对整帧 present 是否节省像素的判定，给事件循环选择 partial/full present 提供统一语义
- `DirtyPresentStrategy` 将 Skip/Partial/Full present 选择显式化，让事件循环能直接消费统一调度决策
- `RenderFrame` 在 graphics 核心层提供 strategy-aware submit plan/result/helper，让 MemorySurface、窗口后端和未来 backend 复用同一套 Skip/Partial/Full 调度
- `RenderFrame` strategy-aware submit plan/result 暴露计划 present rect 数，让后端在提交前后都能复用同一份批量调度 telemetry
- softbuffer 实现 `graphics.Surface` present 契约，并提供 `RenderFrame -> NativeSurface` dirty/full present helper，让窗口示例走统一提交入口
- softbuffer 的 `NativeSurface` 暴露 `RenderFrame` dirty-submit plan 查询，让窗口后端调度能复用 graphics 的统一 dirty snapshot
- softbuffer 的 `NativeSurface` 暴露 `RenderFrame` dirty present batch dry-run，让窗口后端可检查 packed payload 且不触发 hook、不清 dirty
- softbuffer 的 `NativeSurface` 暴露 `RenderFrame` Skip/Partial/Full 策略查询，让窗口后端可直接消费统一 present 决策
- softbuffer 的 `NativeSurface` 暴露 state-aware dirty submit helper，返回 Clean/Present/DirtyClippedAway 与实际提交数量
- softbuffer 的 `NativeSurface` 暴露 strategy-aware frame submit helper，把 Skip/Partial/Full 分派收敛为后端可复用入口
- softbuffer 的 strategy-aware submit result 暴露 state、present rect 数和像素/字节成本，方便窗口后端统一做 telemetry
- softbuffer 的 strategy-aware submit plan/result 保留 dirty bounds 与 bounds-fallback 标记，让窗口后端能区分脏区形状和合并策略
- softbuffer 的 strategy-aware submit plan 支持提交前 dry-run state/cost 查询，不触发 hook、不清 dirty
- softbuffer 的 strategy-aware submit plan/result 暴露计划 present rect 数，方便窗口后端做批量 present 调度和成本统计
- softbuffer 的 strategy-aware submit plan/result 暴露相对整帧 present 的 savings 查询，让窗口后端直接区分 partial/full 成本收益
- `NativeSurface` 支持可选 pre-present hook，让窗口生命周期通知进入统一 present helper，而不是散落在示例事件处理器里
- `headless_render` 示例通过 `RenderFrame::submit_dirty_to` 自校验 dirty submit 状态，让 CI 覆盖可执行的调度结果路径
- `headless_render` 示例通过 graphics-core `RenderFrame::submit_by_strategy_to` 自校验 dry-run plan 与实际 submit 结果，让 CI 覆盖无窗口 Skip/Partial/Full 调度入口
- `hello_world` 示例走 `RenderFrame + LayerTree + softbuffer state-aware frame-submit helpers`，并在 resize/redraw 中复用 frame 与 layer lifecycle，作为事件循环 dirty submit 的最小真实用例
- `hello_world` 示例按 `DirtyPresentStrategy` 分派 Skip/Partial/Full present，把统一 dirty present 策略接入窗口提交路径
- TTF 字体解析（head, hhea, hmtx, cmap, glyf, kern 表）
- 基础文本布局（自动换行、显式换行、空行、行高计算）
- 字形光栅化（直线、二次贝塞尔曲线）与 `CoverageMask` 输出
- 基础反锯齿（glyph 与 path 使用确定性的覆盖率采样）
- 2D 图形渲染（Canvas, Path, Pixmap）
- RGBA alpha 合成与灰度 coverage mask 合成原语
- Pixmap blit、source-rect atlas drawing、source-rect coverage-mask drawing、tiled Pixmap fills、nearest-neighbor/bilinear scaled blit、fast/balanced/high quality strategy、transform-aware sampled Pixmap drawing、`Paint` blend modes、Layer cache、LayerTree 与 straight-alpha 图层合成原语
- Nine-patch Pixmap 缩放合成，作为 GUI 面板、边框和背景图的基础图像缩放能力
- `PixmapCache` 支持按 key 复用 image/layer pixmap，并通过像素拷贝隔离缓存内容，同时提供 hit/insert telemetry，作为 GUI 图像资源缓存基础
- Layer 支持 resize 时保留重叠像素并标记新 cache dirty
- LayerTree 支持位置、尺寸、可见性、opacity、移除、替换和重排触发的旧/新 bounds invalidation
- LayerTree 可将 dirty 合成到 frame canvas 并提交到 `Surface` partial present
- LayerTree/RenderFrame 的 dirty present 失败路径保留可重试 dirty 状态，并回滚失败前合成像素，避免半透明图层重复混合
- RenderFrame 封装 frame canvas、LayerTree、resize lifecycle、dirty query/marking、dirty/full present 与 dirty rect limit，作为事件循环提交单元
- PixelRect/DirtyRegion 合并、Canvas dirty tracking 与 rect present API，作为局部重绘和图层缓存基础
- Renderer Core 组合层：`Font -> render_text_mask -> Canvas.draw_mask`
- Renderer parsed TTF printable ASCII 字符矩阵回归，覆盖 `FontFace -> TextLayout -> Renderer -> Pixmap` 公开路径
- `GlyphMaskCache` 支持按 key 复用单 glyph rendered `CoverageMask`，并可报告 cache hit/rasterize miss telemetry，作为后续 glyph atlas 与 renderer glyph 复用的基础
- `GlyphMaskAtlas` 支持把单 glyph `CoverageMask` 按行打包到 text-local atlas，并复制 mask 像素隔离调用方 mutation，同时暴露 capacity、used/free pixels、occupancy ratio、can-fit 查询、hit/new-insert telemetry 和满载清空重插 helper 供资源生命周期决策使用
- Renderer 可从 `GlyphMaskAtlas` coverage snapshot 按 entry source rect 合成单个 glyph placement，避免为 atlas 子区域额外复制 mask
- Renderer 提供 `draw_text_face_atlas`，让调用方传入 glyph mask cache 与 glyph atlas，按 `TextLayout` 逐 glyph 缓存、打包、合成，并返回 drawn/skipped/cache-hit/rasterized/atlas-hit/atlas-inserted/atlas-clear telemetry
- `TextMaskCache` 支持按 key 复用 rendered `CoverageMask`，并通过像素拷贝隔离缓存内容，同时提供 hit/render miss telemetry，作为 GUI label/text run 缓存基础
- Renderer 提供 `draw_text_face_cached`，让调用方传入 `TextMaskCache` 直接绘制 repeated label/text run，并返回 text-mask cache hit/render telemetry
- Renderer 提供 `RendererTextResources`，让 GUI/resource 代码以单个对象复用 bounded text mask cache、glyph mask cache 与 glyph atlas 状态
- `examples/render_bench` 提供确定性的 CPU render microbenchmark smoke，覆盖 fill_rect、path fill、stroke、glyph raster/mask composition、Pixmap blit 与 present copy telemetry
- Canvas 路径填充（直线/二次/三次曲线展平、4x4 coverage 抗锯齿、transform、NonZero/EvenOdd 填充规则）
- Canvas 路径描边（Butt/Round/Square cap，Miter/Round/Bevel join，dash/dotted）
- 基础 clip rect 与 intersect clip，覆盖 rect/path/stroke/mask/pixel/pixmap 绘制入口
- Canvas save/restore 状态栈，支持嵌套组件绘制时恢复 transform 与 clip
- Win32 窗口管理

### ⚠️ 已知问题
1. `Canvas::draw_text` 已标记废弃；真实文本绘制入口在 `renderer.Renderer::draw_text`，当前已有 parsed TTF printable ASCII 到 Pixmap 的端到端回归，仍需扩展到更多真实字体 fixture
2. 反锯齿质量、glyph fill rule 和不同字号下的 coverage 仍需系统验证
3. 带孔洞字符已有最小回归，并已扩展到 parsed TTF printable ASCII 字符矩阵；仍需扩展到更多真实字体 fixture
4. 仅支持 TTF，不支持 OTF/CFF
5. 字体解析主链路已有 `parse_font_result`；旧 `parse_font` 仍会在错误时 `abort` 以保持兼容，后续需要引导示例和上层调用迁移到 Result 风格入口

---

## 开发阶段

### 第一阶段：核心渲染修复（1-2 周）

#### 0.1 工程与验证基线
- [x] 修复 workspace 中 window 本地依赖的模块名对齐
- [x] 建立根项目验证脚本 `scripts/check_ci.sh`
- [x] 生成并纳入 `graphics/pkg.generated.mbti`
- [x] 清理 `text` 核心包 unused constructor warning，将 `TextDirection::RightToLeft` 与 Unicode line-break class 构造路径转化为可测试行为
- [ ] 将其余核心 warning 分批清理到可审查水平
- [x] 为渲染快照测试确定稳定格式（灰度 mask 文本 dump）

#### 1.1 修复字形渲染缺陷
- [x] 修复扫描线填充算法，正确处理孔洞（counter）
- [x] 实现非零绕数规则（non-zero winding rule）
- [x] 修复连续 off-curve 点的隐式 on-curve 点处理
- [x] 添加基础复合字形（composite glyph）支持
- [x] 为复合字形的 signed byte 偏移、统一缩放、非等比缩放和 2x2 transform 建立白盒回归

#### 1.2 改进反锯齿
- [x] 建立确定性的 4x4 coverage 采样基线
- [ ] 评估并实现更高质量的亚像素/面积覆盖率算法
- [ ] 可选：伽马校正

#### 1.3 测试与验证
- [x] 添加字形渲染快照测试
- [x] 创建测试字体 fixture（覆盖实心 glyph、单孔 glyph、偏移内孔、双孔 glyph、曲线轮廓和 `o`/`d`/`2`/`3` 字符）
- [x] 验证 parsed TTF fixture 中所有 printable ASCII 字符都能映射、布局并渲染到 Pixmap
- [x] 为带孔洞 glyph 建立直接光栅化回归
- [x] 为 `render_text_mask -> Canvas.draw_mask -> Pixmap` 建立组合层单元测试
- [x] 为 `parse_font -> layout_text -> rasterize_glyph -> Pixmap` 建立字体文件端到端测试

#### 1.4 打通真实文本绘制
- [x] 新增 `renderer.Renderer::draw_text`，提供真实 `Font -> layout -> glyph raster -> Canvas` 绘制入口
- [x] 把旧 `Canvas::draw_text` 从占位矩形迁移为废弃兼容入口，并新增明确的 `Canvas::draw_placeholder_text`
- [x] 明确 `FontFace`/`FontData`/`TextLayout`/`GlyphRun` 的第一版公开 API 边界，并让 renderer 示例路径优先走 `FontFace`
- [x] 让 `TextLayout`/`render_text_mask_face`/`Renderer::draw_text_face` 支持 Left/Center/Right 与基础非末行 Justify 对齐，并建立 layout 与像素回归
- [x] 让 `TextLayout`/`render_text_mask_face`/`Renderer::draw_text_face` 保留显式换行与空行，并确保硬换行行不被 Justify 拉伸
- [x] 支持灰度 mask 与 RGBA Pixmap 的 alpha 合成
- [x] 暴露 `Canvas::draw_mask`，作为 `text.Rasterizer` 接入 `graphics` 的低耦合桥接点
- [x] 暴露 `Canvas::draw_mask_rect`、`Renderer::draw_glyph_atlas_entry`、`Renderer::draw_text_face_cached` 与 `Renderer::draw_text_face_atlas`，让 text mask cache、glyph atlas entry 和带 cache/atlas telemetry 的基础 atlas-backed text path 可直接合成到 Pixmap
- [x] 在 `text` 侧产出稳定的 glyph/text mask，并在 `font_demo` 接入 `Canvas::draw_mask`
- [x] 将 `font_demo` 改为调用 Renderer Core 文本绘制入口
- [x] 将旧 `Canvas::draw_text` 的公开 API 迁移到真实字体渲染管线或标记废弃

---

### 第二阶段：字体格式扩展（2-3 周）

这一阶段的重点不是盲目增加格式，而是先把字体 API 边界稳定下来，避免
`Font`、`FontData`、`LayoutResult` 等内部结构过早变成难以演进的公共契约。

#### 2.0 字体 API 稳定化
- [x] 定义 `FontFace`/`FontData`/`GlyphRun`/`TextLayout` 的职责与可见性，见 `docs/text-api-boundaries.md`
- [x] 给字体解析增加 `parse_font_result` Result 风格入口，覆盖 sfnt header、必需表、表范围、核心表长度、cmap 子表结构和 glyf/kern 字节需求错误；旧 `parse_font` 继续作为兼容入口
- [x] 将 `parse_font_result` 的主链路下沉到 head/hhea/hmtx/cmap/maxp/loca/glyf/kern checked 子表解析边界，减少进入 `BinaryReader` 越界 `abort` 的输入面
- [x] 将 glyph outline 的 simple/composite 实际读取改成逐字段 Result 路径，并保留复合 glyph transform 回归
- [x] 继续把 kern pair 与 cmap format 4/12 的实际读取逻辑改成逐字段 Result reader，并为异常 group/rangeOffset 与实际 kerning pair 建立回归
- [x] 将 head/hhea/hmtx/maxp/loca 等剩余兼容 reader 收敛到直接 Result 构造，并用 core metrics、maxp 驱动 loca 长度和 long loca glyph offset 回归覆盖
- [x] 继续收敛 parser 里可达的内部 `abort` 和 ad-hoc error message，补充结构化错误分类覆盖 head/hhea/loca/glyf/cmap 的常见非法结构
- [x] 为 `FontParseError` 建立文档化契约，明确哪些错误属于稳定 public API，哪些仍是兼容迁移期细节，见 `docs/font-parser-errors.md`
- [ ] 建立真实字体 fixture 矩阵：基础 Latin、带孔洞 glyph、复合 glyph、kerning、CJK fallback
- [x] 明确 `text` 包中哪些结构是 facade stable，哪些仍是 implementation-adjacent，见 `docs/text-api-boundaries.md`
- [x] 增加 `FontFaceCache`，让 GUI/resource 代码可按 key 复用 checked `FontFace`、保留解析错误语义，并报告 cache hit/parse telemetry
- [x] 为 `FontFaceCache` 增加 opt-in LRU entry limit，覆盖最近访问刷新、最旧条目淘汰和非法容量 clamp 回归
- [x] 增加 `GlyphMaskCache`，让 renderer/resource 代码可按 key 复用单 glyph mask，并为 cache hit/miss telemetry 与后续 glyph atlas 铺底
- [x] 将 `TextMaskCache` 接入 Renderer，提供 repeated label/text run 的 cached draw path 与 hit/render telemetry
- [x] 为 `GlyphMaskCache`/`TextMaskCache` 增加 opt-in LRU entry limit，覆盖最近访问刷新、最旧条目淘汰和非法容量 clamp 回归
- [x] 增加最小 `GlyphMaskAtlas`，让 renderer/resource 代码可先获得确定性的 glyph mask 行打包 placement、占用 telemetry、hit/insert telemetry 与满载清空重插信号
- [x] 增加 `RendererTextResources`，让 renderer 调用方复用 bounded text/glyph mask cache 与 glyph atlas，并覆盖 cached-mask/atlas draw path 与 clear lifecycle

#### 2.1 OpenType 支持
- [ ] 解析 CFF/CFF2 表（PostScript 轮廓）
- [ ] 支持 OTF 字体文件
- [ ] 解析 GPOS 表（高级定位）
- [ ] 解析 GSUB 表（字形替换）

#### 2.2 高级字体特性
- [ ] 支持可变字体（Variable Fonts）
- [ ] 解析 avar, fvar, stat 表
- [ ] 实例化可变字体轴

#### 2.3 字体集合
- [ ] 支持 TTC/OTC 字体集合
- [ ] 字体选择与匹配

---

### 第三阶段：文本排版增强（2-3 周）

#### 3.1 Unicode 支持
- [ ] 完整 Unicode 字符映射
- [ ] 支持 Unicode 码点 > U+FFFF（代理对）
- [x] 扩展基础 Unicode line-break class 映射，覆盖数字、组合符、Hangul cluster、ZWJ/word joiner、emoji modifier 和非法码点兜底
- [ ] 实现 Unicode 段落与行分割算法（UAX #14, #9）
- [ ] 双向文本支持（BiDi，UAX #9）

#### 3.2 高级排版
- [x] 实现基础文本对齐（左、右、居中、非末行空格拉伸两端对齐）
- [x] 保留显式换行与空行 baseline，硬换行行不参与两端对齐
- [x] 支持字间距调整（tracking）并覆盖 layout、mask 和 renderer 像素回归
- [x] 支持词间距调整（word spacing）并纳入 layout 测量与 glyph advance
- [x] 保留尾随 ASCII 空格的宽度与 glyph run，并避免空格 token 独立开启换行
- [ ] 完善更复杂段落场景的对齐语义（CJK、fallback run）
- [ ] 连字支持（ligatures）

#### 3.3 国际化
- [ ] CJK 文本支持（中日韩）
- [x] `ShapingBuffer` 支持基础 RightToLeft cluster 顺序，并暴露 inspectable shaped glyph/position 访问器
- [ ] 完整从右到左文本（RTL，阿拉伯语、希伯来语，含 BiDi 与 shaping 细节）
- [ ] 垂直文本布局

---

### 第四阶段：图形渲染增强（2-3 周）

#### 4.1 高级路径操作
- [x] Canvas 支持基础路径填充，并与 Pixmap alpha 合成打通
- [x] 路径填充增加稳定 coverage 抗锯齿
- [x] Canvas 支持基础 stroke 路径绘制，复用 4x4 coverage 与 alpha 合成
- [x] Stroke cap 支持 Butt/Round/Square，并为开放/闭合路径建立像素回归
- [x] Stroke join 支持基础 Round/Bevel，并建立外角覆盖回归
- [x] Stroke join 支持 Miter 与 miter limit，并建立退回 Bevel 的像素回归
- [x] Stroke dash/dotted 样式，并建立 dash offset 与点线像素回归
- [x] Canvas 支持基础 clip rect，并覆盖 rect/path/stroke/mask/pixel 绘制入口
- [x] Canvas 支持 save/restore 状态栈，用于嵌套 transform/clip 绘制作用域，并覆盖空栈、嵌套恢复与后续 path 绘制回归
- [x] Canvas 支持 intersect clip，用于 GUI 子树 bounds 逐层收窄，并覆盖空 clip、save/restore 与 dirty region 回归
- [x] Canvas 支持 transform helper（concat/translate/scale/rotate/reset），用于组件局部坐标绘制，并覆盖矩阵顺序、save/restore 与 path 像素回归
- [x] Canvas `fill_rect` 支持当前 transform，与 path/stroke 状态语义保持一致，并覆盖 transformed clip 与 dirty bounds 回归
- [x] Canvas 支持 `stroke_line` helper，用于 GUI 分隔线、下划线和焦点线，并覆盖 path 等价、transform、clip 与 dirty bounds 回归
- [x] Path 与 Canvas 支持 polyline/polygon helper，用于图表折线、简单图标和多边形选择标记，并覆盖 path 结构、helper 等价、transform、clip 与 dirty bounds 回归
- [x] Path 与 Canvas 支持圆弧 stroke 和扇形 fill helper，用于进度环、仪表盘和饼图，并覆盖 cubic 分段、helper 等价、transform、clip 与 dirty bounds 回归
- [x] Canvas 支持 `stroke_rect` helper，用于 GUI 边框和焦点框，并覆盖 path 等价、transform、clip 与 dirty bounds 回归
- [x] Canvas 支持圆形 fill/stroke helper，用于 GUI badge、radio 和 slider knob，并覆盖 path 等价、transform、clip 与 dirty bounds 回归
- [x] Path 与 Canvas 支持椭圆 fill/stroke helper，用于 GUI oval、toggle track 和非等比状态标记，并覆盖 path 结构、helper 等价与 dirty bounds 回归
- [x] Path 支持圆角矩形构造，用于 GUI 面板、按钮和输入框背景，并覆盖半径 clamp、退化矩形与 Canvas 像素回归
- [x] Canvas 支持圆角矩形 fill/stroke helper，复用 path 语义并覆盖 transform、clip、dirty region 与描边像素回归
- [x] Path 与 Canvas 支持每角独立圆角矩形，用于标签页、弹层和非对称面板，并覆盖半径 clamp、path 结构、helper 等价、transform、clip 与 dirty bounds 回归
- [ ] 路径布尔运算（并集、交集、差集）
- [ ] 路径简化与优化

#### 4.2 图像支持
- [ ] PNG/JPEG 解码
- [x] Pixmap 作为源图合成到 Canvas/Pixmap，作为图像与图层缓存基础
- [x] 最近邻 Pixmap 缩放 blit，作为 CPU-first 图像缩放基线
- [x] 增加 bilinear scaled blit，并通过像素回归覆盖透明、裁剪、缩小和放大
- [x] 增加 `ImageSampling` 采样模式 API，统一 nearest/bilinear/bicubic 缩放入口
- [x] 增加 nine-patch Pixmap/Canvas 缩放绘制入口，覆盖角保持、边/中心拉伸、裁剪、opacity 与 dirty region 回归
- [x] 增加 source-rect Pixmap atlas 缩放和平铺绘制入口，覆盖子图采样、越界裁剪、opacity、clip 与 dirty region 回归
- [x] 增加 `PixmapCache`，让 GUI/resource 代码可按 key 复用 image/layer pixmap、隔离 raw pixel mutation，并报告 cache hit/insert telemetry
- [x] 为 `PixmapCache` 增加 opt-in LRU entry limit，覆盖最近访问刷新、最旧条目淘汰和非法容量 clamp 回归
- [x] 增加 transform-aware sampled Pixmap/atlas 绘制入口，覆盖 current transform、clip、nearest/bilinear/bicubic sampling、dirty region 与不可逆 transform 回归
- [x] 增加 bicubic 图像采样，覆盖 Pixmap/Canvas 缩放、source-rect atlas、premultiplied alpha 和 transform-aware sampled Pixmap 回归
- [x] 增加 `ImageQuality`（fast/balanced/high）图像质量策略 API，统一 Pixmap/Canvas 缩放、source-rect、nine-patch 与 transform-aware image drawing 的采样选择
- [x] 增加 `Paint` blend mode（source-over/multiply/screen/add），覆盖 vector、mask、Pixmap blit、scaled image 与 transform-aware sampled image composition 回归

#### 4.3 渲染优化
- [x] `PixelRect`/`DirtyRegion` 数据结构与 Canvas dirty tracking
- [x] `Surface::present_pixels_rect`、`Pixmap::present_rect_to`、`Canvas::present_dirty_to` 基础 partial present 契约
- [x] `MemorySurface` 记录 validated full/rect present 操作，暴露目标 rect、row stride、紧凑像素/字节成本与 source-stride 字节成本，便于测试 present lifecycle
- [x] `PresentRectPayload`/`PresentBatch` 将 Pixmap dirty present plan 物化为可测试 packed rect payload，并让 Canvas dirty submit 复用批量提交路径
- [x] `PresentBatch::validate_for` 在批量 present 前预校验所有 rect，避免后端在后续 rect 失败时留下半提交状态
- [x] `Canvas::dirty_present_batch` 支持提交前 dry-run packed rect batch，并验证不会触发 present 或清理 dirty 状态
- [x] `LayerTree`/`RenderFrame` 支持提交前 dry-run dirty present batch，并验证临时 layer 合成后会恢复 target 像素与 dirty 状态
- [x] Dirty rect 相交/相邻合并与 `Canvas::present_dirty_to_with_limit` 阈值提交策略
- [x] `DirtyRegion::present_plan` 暴露 Empty/Rects/Bounds 提交计划，便于后续事件循环和后端批量 present 共享调度语义
- [x] `Canvas::dirty_present_plan` 将查询计划和实际 dirty present 提交对齐，避免上层重复实现裁剪/阈值 fallback
- [x] `LayerTree`/`RenderFrame` 提供 dirty present plan 查询，并让 layer-tree submit 消费同一份计划以覆盖 canvas 与 layer 脏区
- [x] `DirtySubmitPlan` 暴露 dirty bounds 与 clipped present plan 快照，作为事件循环 dirty submit 调度的可测试中间层
- [x] `DirtySubmitState` 暴露 Clean/Present/DirtyClippedAway 状态，让事件循环和后端调度不再手写 dirty/present 组合判断
- [x] `DirtySubmitResult` 与 `RenderFrame::submit_dirty_to` 返回调度状态和实际提交 rect 数，打通 plan 查询到可消费 submit 结果
- [x] `DirtySubmitResult` 提供 needs-present、clipped-away、dirty bounds 与 fallback 直达查询，让示例和后端少拆一层 plan
- [x] `DirtySubmitResult` 提供 did-present 查询，让窗口循环按提交后事实处理 present 通知与统计
- [x] Dirty present/submit/result 暴露计划提交像素数与紧凑 RGBA 字节数，让事件循环能按成本预算做调度
- [x] Dirty present/submit/result 暴露 partial present 是否节省整帧像素的判定，减少事件循环重复比较逻辑
- [x] `DirtyPresentStrategy` 暴露 Skip/Partial/Full present 决策，给事件循环一个可测试的统一策略枚举
- [x] `RenderFrame` 暴露通用 strategy-aware submit plan/result/helper，把 Skip/Partial/Full 调度从 softbuffer 下沉到 graphics 核心层
- [x] `RenderFrame` strategy-aware submit plan/result 暴露计划 present rect 数，补齐 dry-run 与实际提交结果的批量调度 telemetry
- [x] softbuffer 暴露 `RenderFrame` present strategy 查询，让窗口后端无需拆 dirty-submit plan 就能调度 present
- [x] softbuffer 暴露 `RenderFrame` dirty present batch dry-run，让窗口后端可检查 packed payload 且不触发 hook、不清 dirty
- [x] softbuffer 暴露 strategy-aware frame submit helper，让窗口后端复用统一 Skip/Partial/Full 分派和提交结果
- [x] softbuffer strategy submit result 暴露 state、present rect 数和像素/字节成本，给窗口后端提供统一 telemetry
- [x] softbuffer 暴露 strategy-aware frame submit plan，让窗口后端可在 present 前 dry-run Skip/Partial/Full 调度
- [x] softbuffer strategy submit plan/result 暴露计划 present rect 数，给窗口后端提供提交前批量调度 telemetry
- [x] softbuffer strategy submit plan/result 保留 dirty bounds 与 bounds-fallback 标记，给窗口后端提供更完整的 invalidation telemetry
- [x] softbuffer strategy submit plan/result 暴露 full-present savings 查询，减少窗口后端重复比较 partial/full 成本
- [x] `Layer`/`Pixmap` 缓存原语，支持局部重绘和复用 alpha composition
- [x] `LayerTree` 支持 z-order 图层合成、dirty rect 汇总和基础 invalidation propagation
- [x] `Layer::resize` 保留重叠像素并标记新 bounds dirty
- [x] 图层位置/可见性/opacity 变化触发旧/新 bounds invalidation
- [x] `LayerTree::resize_layer` 支持图层尺寸变化，并覆盖缩小清旧区域与放大重绘回归
- [x] `LayerTree` 支持 remove/replace/reorder 生命周期操作，并覆盖对应 dirty redraw 回归
- [x] `LayerTree::present_dirty_to` 打通图层树 dirty 合成到 `Surface` partial present
- [x] `RenderFrame` 打包 frame canvas、LayerTree 与 dirty rect limit，作为事件循环接入前的提交单元
- [x] `RenderFrame::resize` 保留 frame 重叠像素、LayerTree 状态和 dirty present 策略，并覆盖 resize 后提交回归
- [x] `RenderFrame` 暴露 dirty bounds/has-dirty、mark-all/mark-rect 与 full present helpers，减少上层直接操作 Canvas dirty internals
- [x] `hello_world` 示例接入 `RenderFrame`，覆盖窗口 resize/redraw 上的 frame submit 路径
- [x] `hello_world` resize 复用 `RenderFrame + LayerTree`，通过背景 resize/clear 与文本层 replace/recenter 覆盖 GUI 级 layer lifecycle 基线
- [x] `headless_render` 和 `hello_world` 示例消费 state-aware dirty submit 结果，让无窗口 CI 与窗口 demo 都走统一 submit 语义
- [x] `headless_render` 示例消费 graphics-core strategy-aware submit plan/result，让无窗口 CI 覆盖新的 RenderFrame strategy 调度入口
- [x] `hello_world` 示例按 Skip/Partial/Full 策略选择跳过、dirty submit 或 full present，推进事件循环 dirty present 调度集成
- [x] `hello_world` 示例改为调用 softbuffer strategy-aware submit helper，避免窗口循环重复实现 present 策略分派
- [x] `RenderFrame::resize_and_clear_layer` 抽出背景 layer resize/clear lifecycle helper，让 GUI resize 代码复用统一 dirty 语义
- [ ] 脏矩形渲染调度与窗口事件循环深度集成
- [ ] GUI 级 layer lifecycle：更通用的背景清除策略和 present 调度 API
- [x] 添加确定性 microbenchmark smoke：覆盖 fill_rect、path fill、stroke、glyph raster/mask composition、pixmap blit 与 present copy telemetry
- [ ] GPU 加速（可选，WebGPU/Vulkan）

---

### 第五阶段：跨平台与生态（3-4 周）

#### 5.1 跨平台支持
- [x] 抽象 `Surface` 与 `present(pixels)` 后端接口，并提供可测试 `MemorySurface` 参考后端
- [x] 将 softbuffer/外部原生窗口句柄适配为 `graphics.Surface`，打通 `Canvas/Pixmap -> Surface -> native present`
- [x] 为 `MemorySurface` 和 softbuffer native adapter 增加 rect present 路径，支持 dirty rect 提交验证
- [x] `MemorySurface` 暴露 present-operation records 与聚合 present telemetry，让测试可检查 row stride、dirty rect 顺序、批量 present 形状和 source-stride 成本
- [x] softbuffer 提供 `RenderFrame -> NativeSurface` dirty/full present helper，并覆盖 frame submit 回归
- [x] softbuffer 提供 `RenderFrame -> NativeSurface` dirty-submit plan 查询，并验证查询不会触发 pre-present hook
- [x] softbuffer 提供 state-aware dirty submit helper，并覆盖 Clean/Present/DirtyClippedAway 的 pre-present 行为
- [x] softbuffer 提供 strategy-aware submit plan 查询，并验证 dry-run 不触发 pre-present hook、不消费 frame dirty 状态
- [x] `NativeSurface` 增加 pre-present hook，校验通过后、native present 前触发窗口生命周期通知
- [ ] Windows 支持（Win32）从 demo 后端升级为稳定后端
- [ ] Linux 支持（Wayland，X11 作为后续选项）
- [ ] macOS 支持（AppKit/Cocoa）
- [ ] WebAssembly 支持（Canvas2D/WebGL）
- [ ] present lifecycle：dirty rect 调度、row stride、错误传播和批量 present 调度策略

#### 5.2 API 设计
- [ ] 统一的渲染 API
- [ ] 插件系统（自定义渲染器）
- [ ] 资源管理（字体缓存、图像缓存）

#### 5.3 文档与示例
- [ ] API 文档生成
- [ ] 交互式示例
- [ ] 性能基准测试

---

## 技术债务

### 代码质量
- [ ] 统一错误处理（当前部分使用 abort，部分使用 Result）
- [ ] 添加更多单元测试与快照测试
- [ ] 代码覆盖率分析
- [ ] 性能分析与优化
- [ ] 建立 warning baseline：核心包优先清理，`.local_repos/window` 单独追踪

### 架构改进
- [x] 初步分离渲染后端：`graphics.Surface` + `softbuffer.NativeSurface`
- [ ] 抽象字体加载接口
- [ ] 实现渲染管线（Render Pipeline）
- [ ] 设计资源缓存：font cache 已有带 LRU entry limit 的 `FontFaceCache` 与 hit/parse telemetry，glyph/text mask cache 已有带 LRU entry limit 的 `GlyphMaskCache`/`TextMaskCache`，glyph atlas 已有最小 `GlyphMaskAtlas` 与 occupancy/can-fit telemetry 及 rotate-on-full helper，image cache 已有带 LRU entry limit 的 `PixmapCache`，renderer 已有 `RendererTextResources` 统一复用 text/glyph cache 与 atlas 状态，后续补 image/font loader 集成策略

---

## 里程碑

| 里程碑 | 目标 | 预计时间 |
|--------|------|----------|
| v0.1.0 | 可验证基线：`scripts/check_ci.sh` 稳定通过，graphics/text API 有 `.mbti` | 1-2 周 |
| v0.2.0 | 真实文本渲染链路：TTF -> layout -> glyph raster -> Pixmap/窗口 | 1 个月 |
| v0.3.0 | 文本布局可用：kerning、baseline、对齐、ASCII 快照回归 | 2 个月 |
| v0.4.0 | Canvas API 成型：path fill/stroke、clip、transform、alpha blending | 3 个月 |
| v0.5.0 | 后端抽象：Surface/present/event loop 与渲染核心解耦 | 4 个月 |
| v1.0.0-alpha | 可作为 MoonBit GUI 基础库：文档、示例、测试、benchmark 完整 | 6 个月 |

### 里程碑验收标准

- **v0.1.0**：`scripts/check_ci.sh` 通过；`graphics`、`text`、`renderer`、`softbuffer`
  都有 `.mbti` 或明确的 public API 审查记录；核心包 warning 有清单。
- **v0.2.0**：`font_demo` 和测试都走 `renderer.Renderer::draw_text`；旧
  `Canvas::draw_text` 只保留废弃兼容；真实 TTF bytes 到 `Pixmap` 有端到端回归。
- **v0.3.0**：Latin/ASCII glyph matrix 已有 parsed TTF -> Pixmap 回归；kerning、baseline、alignment、line break 有稳定回归；
  `FontFace`/`GlyphRun`/`TextLayout` 边界确定。
- **v0.4.0**：Canvas 的 fill/stroke/clip/transform/image/mask API 有像素级测试；
  alpha composition 行为文档化。
- **v0.5.0**：窗口 present 不再依赖示例内特殊逻辑；resize、row stride、dirty rect 调度和错误传播
  都有测试或 build-only 验证。
- **v1.0.0-alpha**：至少一个真实 GUI 示例、一个 headless rendering 示例、一组 benchmark、
  一份 API guide 和跨平台验证矩阵。

### 未来 90 天建议节奏

1. **第 1-2 周：收敛基线**
   固定 public API 审查流程，清理核心 warning，补齐 ASCII/glyph snapshot，并把 parser `abort`
   的替换方案定下来。
2. **第 3-5 周：文本可用性**
   定义 `FontFace`、`GlyphRun`、`TextLayout`，完善 kerning、baseline、alignment、line break，
   扩展真实字体 fixture。
3. **第 6-8 周：Canvas 与图像层**
   在现有 layer tree 与 RenderFrame resize lifecycle 基础上补 dirty rect 调度、更高质量采样和更多 path/stroke 回归。
4. **第 9-12 周：后端与示例**
   标准化 `Surface` lifecycle，完善 window resize/present 示例，补一个 headless PNG/fixture 输出方向，
   开始 benchmark 和文档化。

---

## 优先级排序

### P0（立即修复）
1. 保持 `scripts/check_ci.sh` 作为提交前验证入口
2. 将测试字体矩阵继续扩展到更多真实字体 fixture（printable ASCII fixture 已覆盖映射、布局与渲染，仍需更多真实轮廓）
3. 扩展 `FontFace`/`TextLayout`/`FontFaceCache`/`TextMaskCache`/`GlyphMaskAtlas` facade 使用面：更多示例和未来 GUI 代码优先走 checked face API、cached mask API 与 atlas placement API；renderer 已有基础 atlas-backed text path，后续补 eviction 策略和更完整的多字体/fallback pipeline
4. 继续推进 parser 错误处理迁移：`parse_font_result` 主链路已覆盖核心表、cmap、glyf、kern 的逐字段 Result 读取；下一步是继续减少上层 legacy `parse_font` 使用，并审查 `InvalidTable` 是否保留为迁移期兜底
5. 改进反锯齿质量，并保留确定性像素回归

### P1（短期）
1. 图层缓存、layer lifecycle 调度与 partial present
2. 更高质量采样与 present lifecycle 调度
3. kerning、baseline、line break 和复杂段落对齐的文本布局增强

### P2（中期）
1. OTF/CFF 字体支持
2. 高级排版特性
3. PNG/JPEG 或最小 PNG 解码方向
4. CJK 与字体 fallback

### P3（长期）
1. 跨平台支持
2. GPU 加速
3. 插件/自定义 renderer 扩展点
4. benchmark 与 release 质量门槛

---

## 参考资源

- [OpenType 规范](https://docs.microsoft.com/en-us/typography/opentype/spec/)
- [TrueType 规范](https://developer.apple.com/fonts/TrueType-Reference-Manual/)
- [Unicode 文本分割](https://unicode.org/reports/tr14/)
- [Unicode 双向算法](https://unicode.org/reports/tr9/)
- [FreeType 源码](https://gitlab.freedesktop.org/freetype/freetype)（参考实现）
- [font-rs](https://github.com/raphlinus/font-rs)（Rust 字体光栅化）
- [tiny-skia](https://github.com/RazrFalcon/tiny-skia)（Rust 2D 渲染）
