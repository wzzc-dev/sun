# tiny-skia 实现详解

## 🏗️ 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                      tiny-skia                              │
├─────────────────────────────────────────────────────────────┤
│  Pixmap (像素缓冲区)                                        │
│    └─ FillRule (填充规则)                                    │
│    └─ Transform (变换矩阵)                                  │
│    └─ ClipMask (裁剪遮罩)                                   │
├─────────────────────────────────────────────────────────────┤
│  PathBuilder → Path (路径构建)                               │
│    └─ MoveTo / LineTo / QuadTo / CubicTo / Close            │
├─────────────────────────────────────────────────────────────┤
│  ScanlineConverter (扫描线转换)                              │
│    └─ Edge (边)                                             │
│    └─ Scanline (扫描线)                                     │
│    └─ CoverageMask (覆盖率遮罩)                             │
├─────────────────────────────────────────────────────────────┤
│  Blitter (像素混合器)                                        │
│    └─ ColorBlitter (纯色)                                   │
│    └─ LinearGradientBlitter (线性渐变)                       │
│    └─ PatternBlitter (图案)                                 │
└─────────────────────────────────────────────────────────────┘
```

## 📐 核心数据结构

### 1. Path (路径)
```rust
pub struct Path {
    verbs: Vec<PathVerb>,      // 动词列表
    points: Vec<Point>,        // 点列表
    bounds: Rect,              // 边界框
}

pub enum PathVerb {
    MoveTo,
    LineTo,
    QuadTo,    // 二次贝塞尔
    CubicTo,   // 三次贝塞尔
    Close,
}
```

### 2. Transform (变换矩阵)
```
| a  b  tx |     | sx  shx tx |
| c  d  ty |  =  | shy sy  ty |
| 0  0  1  |     | 0   0   1  |
```

### 3. Scanline (扫描线)
```rust
pub struct Scanline {
    y: i32,
    spans: Vec<ScanlineSpan>,
}

pub struct ScanlineSpan {
    x: i32,
    len: u32,
    coverage: u8,  // 0-255 覆盖率
}
```

## 🔄 渲染流程

### Step 1: 路径变换
```rust
fn transform_path(path: &Path, transform: &Transform) -> Path {
    // 对每个点应用变换矩阵
    for point in path.points.iter_mut() {
        *point = transform.map_point(*point);
    }
}
```

### Step 2: 曲线细分 (Flatten)
```rust
fn flatten_cubic(p0: Point, p1: Point, p2: Point, p3: Point) -> Vec<LineSegment> {
    // 递归细分三次贝塞尔曲线
    if is_flat_enough(p0, p1, p2, p3) {
        return vec![LineSegment::new(p0, p3)];
    }
    
    // De Casteljau 算法细分
    let (left, right) = subdivide_cubic(p0, p1, p2, p3, 0.5);
    let mut result = flatten_cubic(left.0, left.1, left.2, left.3);
    result.extend(flatten_cubic(right.0, right.1, right.2, right.3));
    result
}
```

### Step 3: 扫描线转换
```rust
fn path_to_scanlines(edges: &[Edge], fill_rule: FillRule) -> Vec<Scanline> {
    let mut scanlines = Vec::new();
    let mut active_edges = Vec::new();
    
    // 按 Y 坐标排序边
    edges.sort_by(|a, b| a.y_start.cmp(&b.y_start));
    
    for y in y_min..=y_max {
        // 激活新的边
        activate_edges(&mut active_edges, edges, y);
        
        // 计算交点
        let intersections = compute_intersections(&active_edges, y);
        
        // 应用填充规则
        let spans = apply_fill_rule(intersections, fill_rule);
        
        // 计算覆盖率（抗锯齿）
        let coverage_spans = compute_coverage(spans, y);
        
        scanlines.push(Scanline { y, spans: coverage_spans });
        
        // 移除完成的边
        remove_finished_edges(&mut active_edges, y);
    }
    
    scanlines
}
```

### Step 4: 像素混合
```rust
fn blit_scanline(dst: &mut [u8], scanline: &Scanline, color: Color) {
    for span in &scanline.spans {
        for x in span.x..(span.x + span.len as i32) {
            let alpha = span.coverage as f32 / 255.0;
            let src = color.premultiply();
            
            // SrcOver 混合
            let dst_pixel = get_pixel(dst, x, scanline.y);
            let result = blend_premultiplied(src, dst_pixel, alpha);
            set_pixel(dst, x, scanline.y, result);
        }
    }
}
```

## 🎨 关键算法

### 1. 抗锯齿覆盖率计算

```rust
// 计算像素被路径覆盖的面积比例
fn compute_pixel_coverage(
    pixel_rect: Rect,
    edges: &[Edge],
) -> f32 {
    // 方法1: 超采样 (Supersampling)
    let samples = 4; // 4x4 = 16 个子采样点
    let mut covered = 0;
    
    for sy in 0..samples {
        for sx in 0..samples {
            let sample_x = pixel_rect.x + (sx as f32 + 0.5) / samples as f32;
            let sample_y = pixel_rect.y + (sy as f32 + 0.5) / samples as f32;
            
            if is_point_in_path(sample_x, sample_y, edges) {
                covered += 1;
            }
        }
    }
    
    covered as f32 / (samples * samples) as f32
}
```

### 2. 填充规则实现

```rust
// Even-Odd Rule
fn is_inside_even_odd(x: f32, y: f32, edges: &[Edge]) -> bool {
    let mut crossings = 0;
    for edge in edges {
        if edge.intersects_horizontal_ray(x, y) {
            crossings += 1;
        }
    }
    crossings % 2 == 1
}

// Non-Zero Winding Rule
fn is_inside_non_zero(x: f32, y: f32, edges: &[Edge]) -> bool {
    let mut winding = 0;
    for edge in edges {
        if edge.crosses_upward(x, y) {
            winding += 1;
        } else if edge.crosses_downward(x, y) {
            winding -= 1;
        }
    }
    winding != 0
}
```

### 3. Alpha 混合 (Premultiplied)

```rust
// 预乘 Alpha 混合
fn blend_premultiplied(src: ColorU8, dst: ColorU8, alpha: f32) -> ColorU8 {
    let inv_alpha = 1.0 - alpha;
    
    ColorU8 {
        r: (src.r as f32 + dst.r as f32 * inv_alpha) as u8,
        g: (src.g as f32 + dst.g as f32 * inv_alpha) as u8,
        b: (src.b as f32 + dst.b as f32 * inv_alpha) as u8,
        a: (src.a as f32 + dst.a as f32 * inv_alpha) as u8,
    }
}
```

## 📊 性能优化

### 1. 边界框裁剪
```rust
fn render_path(path: &Path, pixmap: &mut Pixmap) {
    // 只处理路径边界框内的像素
    let bounds = path.bounds().intersect(pixmap.bounds());
    if bounds.is_empty() {
        return;
    }
    
    // 只扫描相关的扫描线
    for y in bounds.top()..bounds.bottom() {
        render_scanline(y, path, pixmap);
    }
}
```

### 2. 边的活性列表
```rust
struct ActiveEdgeList {
    edges: Vec<Edge>,
}

impl ActiveEdgeList {
    fn update(&mut self, y: i32) {
        // 移除已结束的边
        self.edges.retain(|e| e.y_end > y);
        
        // 按 x 坐标排序（用于快速查找交点）
        self.edges.sort_by(|a, b| a.current_x.partial_cmp(&b.current_x));
    }
}
```

### 3. 缓存友好的内存布局
```rust
// 连续内存布局，对 CPU 缓存友好
struct Pixmap {
    width: u32,
    height: u32,
    data: Vec<u8>,  // RGBA 连续存储
}

impl Pixmap {
    fn pixel_mut(&mut self, x: u32, y: u32) -> &mut [u8] {
        let offset = ((y * self.width + x) * 4) as usize;
        &mut self.data[offset..offset + 4]
    }
}
```

## 🆚 与 Skia 的区别

| 特性 | tiny-skia | Skia |
|------|-----------|------|
| 语言 | Rust | C++ |
| GPU | ❌ | ✅ (OpenGL/Vulkan/Metal) |
| 路径操作 | 基础 | 完整 (布尔运算) |
| 文本渲染 | ❌ | ✅ (HarfBuzz + FreeType) |
| 渐变 | 线性/径向 | 完整 (含锥形) |
| 图层 | ❌ | ✅ (saveLayer) |
| 性能 | 中等 | 极高 |
| 代码量 | ~5k 行 | ~500k 行 |

## 💡 总结

tiny-skia 的核心就是：
1. **路径 → 边 (Edges)**
2. **边 → 扫描线 (Scanlines)**
3. **扫描线 → 覆盖率遮罩 (Coverage Mask)**
4. **遮罩 → 混合像素 (Blended Pixels)**

这是一个经典的 **软件光栅化** 流程，所有 2D 渲染库 (包括 Skia) 的核心都是这个算法。
