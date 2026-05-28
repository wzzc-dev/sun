# wzzc-dev 开发路线图

## 项目概述

wzzc-dev 是一个 MoonBit 语言的 2D 图形与文本渲染库，包含三个核心模块：
- **graphics** - 2D 图形渲染
- **text** - 文本处理与字体渲染
- **softbuffer** - 窗口管理与像素显示

---

## 当前状态评估

### ✅ 已完成
- TTF 字体解析（head, hhea, hmtx, cmap, glyf, kern 表）
- 基础文本布局（自动换行、行高计算）
- 字形光栅化（直线、二次贝塞尔曲线）
- 基础反锯齿（边缘检测）
- 2D 图形渲染（Canvas, Path, Pixmap）
- Win32 窗口管理

### ⚠️ 已知问题
1. 反锯齿效果粗糙（仅边缘像素降权）
2. 部分字符渲染缺失（o, d, 2, 3 等有孔洞的字符）
3. 不支持复合字形（composite glyphs）
4. 仅支持 TTF，不支持 OTF/CFF

---

## 开发阶段

### 第一阶段：核心渲染修复（1-2 周）

#### 1.1 修复字形渲染缺陷
- [ ] 修复扫描线填充算法，正确处理孔洞（counter）
- [ ] 实现非零绕数规则（non-zero winding rule）
- [ ] 修复连续 off-curve 点的隐式 on-curve 点处理
- [ ] 添加复合字形（composite glyph）支持

#### 1.2 改进反锯齿
- [ ] 实现亚像素覆盖率计算
- [ ] 基于面积的覆盖率算法
- [ ] 可选：伽马校正

#### 1.3 测试与验证
- [ ] 添加字形渲染快照测试
- [ ] 创建测试字体文件（包含各种边界情况）
- [ ] 验证所有 ASCII 字符正确渲染

---

### 第二阶段：字体格式扩展（2-3 周）

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
- [ ] 实现 Unicode 段落与行分割算法（UAX #14, #9）
- [ ] 双向文本支持（BiDi，UAX #9）

#### 3.2 高级排版
- [ ] 实现文本对齐（左、右、居中、两端对齐）
- [ ] 字间距调整（tracking）
- [ ] 词间距调整（word spacing）
- [ ] 连字支持（ligatures）

#### 3.3 国际化
- [ ] CJK 文本支持（中日韩）
- [ ] 从右到左文本（RTL，阿拉伯语、希伯来语）
- [ ] 垂直文本布局

---

### 第四阶段：图形渲染增强（2-3 周）

#### 4.1 高级路径操作
- [ ] 路径布尔运算（并集、交集、差集）
- [ ] 路径简化与优化
- [ ] 虚线与点线样式

#### 4.2 图像支持
- [ ] PNG/JPEG 解码
- [ ] 图像缩放与变换
- [ ] 图像与图形混合

#### 4.3 渲染优化
- [ ] 脏矩形渲染
- [ ] 图层合成
- [ ] GPU 加速（可选，WebGPU/Vulkan）

---

### 第五阶段：跨平台与生态（3-4 周）

#### 5.1 跨平台支持
- [ ] Linux 支持（X11/Wayland）
- [ ] macOS 支持（Cocoa）
- [ ] WebAssembly 支持（Canvas2D/WebGL）

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
- [ ] 添加更多单元测试（当前仅 21 个）
- [ ] 代码覆盖率分析
- [ ] 性能分析与优化

### 架构改进
- [ ] 分离渲染后端（当前硬编码 Win32 GDI）
- [ ] 抽象字体加载接口
- [ ] 实现渲染管线（Render Pipeline）

---

## 里程碑

| 里程碑 | 目标 | 预计时间 |
|--------|------|----------|
| v0.1.0 | 修复核心渲染，所有 ASCII 字符正确显示 | 2 周 |
| v0.2.0 | 支持 OTF 字体，基础 Unicode 支持 | 1 个月 |
| v0.3.0 | 完整文本排版，CJK 支持 | 2 个月 |
| v0.4.0 | 图像支持，高级图形操作 | 3 个月 |
| v1.0.0 | 跨平台，完整 API，文档 | 6 个月 |

---

## 优先级排序

### P0（立即修复）
1. 修复 o, d, 2, 3 等字符的渲染缺失
2. 改进反锯齿质量

### P1（短期）
1. 复合字形支持
2. 更多测试用例
3. Unicode 完整支持

### P2（中期）
1. OTF/CFF 字体支持
2. 高级排版特性
3. 图像支持

### P3（长期）
1. 跨平台支持
2. GPU 加速
3. 插件系统

---

## 参考资源

- [OpenType 规范](https://docs.microsoft.com/en-us/typography/opentype/spec/)
- [TrueType 规范](https://developer.apple.com/fonts/TrueType-Reference-Manual/)
- [Unicode 文本分割](https://unicode.org/reports/tr14/)
- [Unicode 双向算法](https://unicode.org/reports/tr9/)
- [FreeType 源码](https://gitlab.freedesktop.org/freetype/freetype)（参考实现）
- [font-rs](https://github.com/raphlinus/font-rs)（Rust 字体光栅化）
- [tiny-skia](https://github.com/RazrFalcon/tiny-skia)（Rust 2D 渲染）
