# 文档库项目说明（MkDocs + Material）

本项目是基于 MkDocs 与 Material 主题的个人文档库，使用 Poetry 管理依赖，通过 GitHub Actions 部署到 GitHub Pages。

## 目录结构与作用

```
.
├─ docs/                    # 文档源文件（Markdown、静态资源、JS/CSS）
│  ├─ index.md              # 站点首页
│  ├─ 开发/                 # 开发相关文档
│  ├─ 随笔/                 # 未归类的文档
│  ├─ 项目/                 # 项目类文档
│  ├─ 工具/                 # 工具使用笔记
│  ├─ assets/               # 图片等静态资源
│  ├─ javascripts/extra.js  # 自定义前端脚本
│  └─ stylesheets/*.css     # 自定义样式
├─ overrides/               # 主题模板覆盖（Jinja2 模板）
│  └─ main.html             # 注入面包屑/元信息的自定义模板
├─ .github/workflows/deploy.yml  # GitHub Actions 部署配置（Pages Actions）
├─ mkdocs.yml               # MkDocs 站点配置
├─ start.sh                 # 本地开发/预览脚本（后台运行、日志、状态管理）
├─ pyproject.toml           # Poetry 配置与依赖声明
├─ poetry.lock              # 锁定依赖版本
├─ logs/                    # 本地开发日志目录
├─ site/                    # 构建输出目录（已被 .gitignore 忽略）
├─ .cache/                  # 构建缓存（已被 .gitignore 忽略）
└─ .gitignore               # Git 忽略规则
```

## 关键配置与自定义

- `mkdocs.yml`
  - 主题：Material（`theme.name: material`），自定义模板目录 `overrides/`
  - 常用特性：导航、目录、代码复制/注释、搜索高亮等
  - 插件：`search`、`tags`、`social`、`meta-descriptions`、`blog`
    - `blog.blog_dir: 随笔`，将 `docs/随笔/` 作为博客文章目录
  - 资源：引入 `MathJax`、`font-awesome`，以及本地 `javascripts/extra.js`、`stylesheets/extra.css`
  - `site_dir: site` 指定构建输出目录

- `overrides/main.html`
  - 继承主题 `base.html`，在文章顶部注入“路径导航（面包屑）”与“元数据（创建/更新时间）”。
  - 若需显示时间信息，请在 Markdown 的 Front Matter 中添加字段：
    ```yaml
    ---
    title: 标题
    date: 2025-10-06
    date_modified: 2025-10-06
    tags: [示例]
    ---
    ```

- `.github/workflows/deploy.yml`
  - 采用 GitHub Pages Actions 流程：
    1) 构建站点（`mkdocs build`）
    2) 上传构建产物为 Pages Artifact
    3) 使用 `actions/deploy-pages` 部署
  - 仅监听 `main` 分支，无需 `gh-pages` 分支。
  - 仓库 Settings → Pages 的 Source 应设置为 “GitHub Actions”。

## 本地开发与预览

前置依赖：
- 已安装 Python（建议 3.10+）与 Poetry

初始化依赖：
```bash
poetry install --no-root
```

启动本地预览（推荐使用脚本）：
```bash
./start.sh start     # 后台启动，默认 0.0.0.0:8000，日志写入 logs/mkdocs.log
./start.sh status    # 查看状态
./start.sh logs      # 实时查看日志
./start.sh restart   # 重启
./start.sh stop      # 停止
```

等价的直接命令（当前 shell 中）：
```bash
poetry run mkdocs serve -a 0.0.0.0:8000
```

本地构建（如需手动产出静态文件）：
```bash
poetry run mkdocs build --clean --site-dir site
```

说明：`site/` 与 `.cache/` 为构建产物/缓存目录，已加入 `.gitignore`，可随时删除，构建时会重新生成。

## CI/CD 与部署

触发方式：
- 推送到 `main` 分支会自动触发构建与部署；也可手动 `workflow_dispatch`。

流程概览：
1. Actions 检出仓库，设置 Python 3.12，安装 Poetry 与依赖。
2. 执行 `mkdocs build` 生成 `site/`。
3. `actions/upload-pages-artifact` 上传构建产物。
4. `actions/deploy-pages` 将 Artifact 部署到 GitHub Pages。

首次切换到 Pages Actions 后的检查项：
- Actions 工作流 “Deploy MkDocs” 运行为绿色（`build`、`deploy` 两个 Job 成功）。
- Settings → Pages 显示来源为 GitHub Actions，站点 URL 正常可访问。
- 历史 `gh-pages` 分支可删除（现流程不再使用）。

## 内容组织与约定

- 文档放在 `docs/`，按主题归类：`开发/`、`随笔/`、`项目/`、`工具/` 等。
- 博客文章放在 `docs/随笔/`，由 `blog` 插件生成列表与目录。
- 静态资源放入 `docs/assets/`，引用路径以 `assets/...` 开头。
- 如需标签，请在 Front Matter 的 `tags` 中声明，配合 `tags` 插件。

## 常见问题

- 站点未更新/404：
  - 查看 GitHub Actions 日志是否构建/部署成功；
  - 确认 Pages Source=GitHub Actions；
  - 如有缓存问题，可清理本地 `site/`、`.cache/` 后重试。

- 本地端口冲突：
  - 使用环境变量覆盖：`ADDR=127.0.0.1 PORT=8080 ./start.sh start`

## 维护建议

- 定期更新依赖：
```bash
poetry update
```
- 锁定核心依赖版本（如 `mkdocs-material`）以避免主题大版本变更带来的样式/行为差异。
- 在 PR 中开启 Actions 以提前发现构建与链接问题。

---

如需进一步自动化（如链接校验、拼写检查、图像压缩等），可在 Actions 中按需扩展步骤。

