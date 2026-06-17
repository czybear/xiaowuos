# 软件纪事题图 SOP

## 概述

本 SOP 用于为软件纪事（Software Chronicle）生成标准化的题图封面。通过自动化流程确保每期纪事的视觉风格一致、质量稳定。

---

## 前置条件

- **AI 图像生成工具可用**（如 `image_generate`、DALL-E、Stable Diffusion 等）
- **品牌设计元素**：
  - 主色调：建议定义一组品牌色（如深色背景 + 强调色）
  - Logo 位置：右上角或左下角固定位置
  - 字体规范：标题使用无衬线字体，副标题/正文使用易读字体
  - 版式：标题居左/居中，留白比例 30-40%

---

## 流程步骤

### 步骤 1：内容提炼（人工/AI）

**输入**：纪事文章/本期主题

**任务**：提取核心视觉元素

**输出**：
- 核心关键词（3-5 个）
- 主题描述（1-2 句话）
- 视觉风格偏好（现代/复古/抽象/极简等）

> 💡 **工具支持**：用当前模型总结文章内容，输出摘要 + 关键词

---

### 步骤 2：Prompt 构建

**模板**：
```
[视觉风格]，[核心元素描述]，[色彩方案]，[构图方式]

示例：
A cinematic wide shot of a futuristic software developer's workspace, 
floating holographic code in deep blue and purple tones, 
minimalist composition with negative space on the left for text,
dark ambient lighting, 4K resolution, hyperrealistic detail
```

**关键参数**：
- **aspectRatio**：16:9（适合标题栏）或 3:2（通用）
- **resolution**：4K 或 1080p
- **风格关键词**：根据品牌定义调整

---

### 步骤 3：图像生成

**执行**：
```bash
image_generate action=generate
  prompt: <步骤 2 构建的 prompt>
  aspectRatio: 16:9
  resolution: 4K
  filename: software-chronicle-YEAR-MMDD-title.png
```

**生成建议**：
- 批量生成 2-4 张候选图（`count=4`）
- 保留原始 prompt 以便后续调整

---

### 步骤 4：后期处理（可选）

**添加元素**：
- Logo：覆盖到固定位置
- 期号标识：左上角或右上角
- 标题文字：使用图像编辑工具或设计软件
- 滤镜/调色：确保与品牌视觉一致

**工具推荐**：
- `nano-pdf`（PDF 编辑）
- 图像编辑 CLI（如有安装）
- 或手动使用 Figma/Photoshop

---

### 步骤 5：质量核验

**检查项**：
- ✅ 视觉清晰度（无模糊、噪点）
- ✅ 留白区域足够放置标题
- ✅ 色彩符合品牌规范
- ✅ 无版权风险元素
- ✅ 文件命名符合规范

**验收标准**：
- 主图分辨率 ≥1920×1080
- 文件大小 <5MB（便于传播）
- 格式：PNG/JPG

---

### 步骤 6：发布与归档

**输出**：
- 主图：`software-chronicle-2026-04-20-topic-title.png`
- 缩略图：从主图裁剪，尺寸 640×360
- 元数据：记录生成日志（prompt、参数、生成时间）

**归档路径**：
```
/workspace/software-chronicle/images/
├── 2026/
│   ├── 04/
│   │   ├── software-chronicle-2026-04-20-topic-title.png
│   │   ├── software-chronicle-2026-04-20-thumbnail.png
│   └── _meta.json
```

---

## 自动化脚本（可选）

### `cronicle-image-gen.sh`

```bash
#!/bin/bash
# 软件纪事题图生成脚本

SUBJECT=$1
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="/workspace/software-chronicle/images/$(date +%Y)/$(date +%m)"

# 确保目录存在
mkdir -p "$OUTPUT_DIR"

# 生成图像（调用 image_generate）
image_generate \
  --prompt "cyberpunk software developer workspace, $SUBJECT, neon blue and purple colors, cinematic lighting, 16:9 aspect ratio, 4K" \
  --aspectRatio 16:9 \
  --resolution 4K \
  --filename "software-chronicle-${DATE}-$SUBJECT.png"

echo "✅ Image generated at: $OUTPUT_DIR"
```

---

## 风格参考库

### 通用风格模板

| 风格名称 | Prompt 关键词 | 适用场景 |
|---------|-------------|---------|
| **未来科技** | futuristic, holographic, neon, cyberpunk, deep blue/purple | AI、区块链、前沿技术 |
| **简约现代** | minimalist, white space, clean lines, geometric | 工具、SaaS、B 端产品 |
| **复古游戏** | pixel art, 8-bit, retro, vaporwave | 游戏、怀旧主题 |
| **抽象概念** | abstract, fluid, gradient, geometric shapes | 方法论、思考类内容 |
| **摄影写实** | photography, real-world, cinematic lighting | 实践案例、现场分享 |

---

## 常见问题

**Q：生成的图像文字区域不够怎么办？**
A：在 prompt 中明确"leave negative space for text on the left/right/center"

**Q：如何保持一致的风格？**
A：建立风格库，每期调用相同的 prompt 模板 + 调整关键词

**Q：需要添加文字标题怎么办？**
A：生成底图后通过设计工具添加文字，或生成时注明"leave top area for title"

---

## 维护与迭代

- **每月回顾**：收集反馈，调整风格偏好
- **建立样式库**：记录成功的 prompt + 图像配对
- **版本管理**：每次大改记录变更

---

## 附录

### 相关文件
- [品牌视觉规范](/configs/brand-guidelines.md)
- [图像生成 API 文档](/docs/image-generation.md)

### 工具依赖
- AI 图像生成工具：`image_generate` 或外部 API
- 图像处理工具：可选
- 文字设计工具：Figma/Photoshop/Canva
