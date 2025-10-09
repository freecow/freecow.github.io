---
aliases: 
tags: 
date_modified: 
date: 2025-10-9
---

# 提示词

目前Typora内置的Mermaid版本为11.9.0，实测绘制图形时还是有不少注意的地方

```
帮我用Mermaid绘制一个本项目的架构图，以下为注意事项：

基本格式

- 使用代码围栏：mermaid …
- 图类型常用：flowchart（LR/TB）、sequenceDiagram、classDiagram、stateDiagram、erDiagram、gantt、pie
- 方向：flowchart LR（从左到右）/ TB（从上到下）

节点命名与文本

- 节点ID使用简单字母组合（如 API、CORE、DB、ADP），避免中文或特殊字符作为 ID。
- 节点可使用中文文本（放在 [] 内），例如 FE[前端]、API[Flask API]。
- 多行文本：使用 <br/>，不要用 \n（在 Typora 11.9 中 \n 可能不被识别或导致报错）。
- 避免节点文本中使用星号 、尖括号 <>、竖线 | 等“可能触发解析”的特殊符号；必要时用全称替代（例如 “/apiendpoints” 代替 “/api/”），或改为图下说明文字。

连线与标签

- 普通连线：A --> B
- 双向连线：A <--> B
- 标签连线：A -->|SQL| DB（注意：标签中的特殊字符尽量避免 *、<> 等）
- 建议使用简短英文短语作为连线标签，如 “SQL”、“REST”、“CRUD config”、“read/write config”

分组（子图）

- subgraph 分组可用英文标题，例如 subgraph BE[Backend] … end
- 中文标题也可，但避免里面包含特殊字符
- 子图内各节点仍使用简单 ID

样式与主题

- 用 classDef 定义样式：classDef accent fill:#E6F7FF,stroke:#1890ff,stroke-width:1px;
- 通过 class FE,BE,CFG accent; 把样式应用到节点
- 颜色用标准 HEX，透明背景建议导出时设置

常见错误与规避

- Syntax error: got 'PS' 等：大多由节点文本/连线标签中的特殊字符引发，检查是否包含 、|、<、>、/api/等；改为 <br/> 或简写文本。
- “Parse error on line X” 指向 subgraph/节点的行：检查节点标签是否有换行符 \n，替换为 <br/>；去掉额外的中英文标点。
- 大段中文文本尽量拆分成图下说明，而非全部写到节点文本中。

复杂图拆分建议

- 一张图只表达一个维度（如“高层组件与数据流”）；第二张图再画“生命周期/时序/数据路径”
- 节点标签尽量简短，把“说明细节”放到图下 bullet 列表中，便于阅读和兼容
```

