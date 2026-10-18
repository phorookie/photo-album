# 欣赏相册集

个人摄影欣赏相册：分层分类 + 构图分析图层 + 好/坏评论 + 标签检索。纯前端单页应用，数据全部存在浏览器本地（IndexedDB），可安装为 PWA、可离线使用。

## 功能

- 分层分类（商业摄影 / 爱好者摄影…，分组只汇总、不可直接存图）
- 构图分析图层：手绘 / 直线 / 箭头 / 矩形 + 参考线（三分 / 黄金分割），线条可选中拖动编辑、可导出分析图
- 好 / 坏 评论，以及**结构化笔记**（色调 / 光线 / 情绪 / 构图 / 可借鉴点 / 雷区 六个维度，随时补写）
- 标签（12 个预设 + 自定义）、全库搜索与筛选
- **学习卡导出**：把照片 + 构图线 + 结构化笔记 + 好/坏评论 合成一张 PNG，便于保存与分享
- 双图对比（联动 / 独立缩放、原尺寸、三分线）、查看器内缩放与平移
- 笔记汇总导出（HTML / Markdown）、整库备份与恢复
- PWA 可安装、离线可用

## 文件结构

```
album.html                 相册主应用（单文件，全部功能都在里面）
album-manifest.webmanifest PWA 清单（安装到主屏幕用）
album-sw.js                Service Worker（离线可用）
album-icon.svg             图标源文件
album-icon-192.png         PWA 图标 192
album-icon-512.png         PWA 图标 512
make_icons.py              图标生成脚本（改图标才用得上）
config.js                  Supabase 配置 + 云同步开关（不开云同步可不管）
supabase/album-schema.sql  云同步所需的表结构与权限（不开云同步可不管）
.github/workflows/         GitHub Pages 自动部署
```

## 本地预览

需要通过 http 打开（`file://` 下 IndexedDB 会被浏览器拦）：

```bash
python -m http.server 8080
# 打开 http://localhost:8080/album.html
```

## 部署

推到 `main` 分支即自动部署到 GitHub Pages（Actions 里看进度），地址为
`https://<用户名>.github.io/<仓库名>/album.html`。

手机安装：Android Chrome 菜单 →「安装应用 / 添加到主屏幕」；iOS Safari → 分享按钮 →「添加到主屏幕」。

## 云同步（可选，默认关闭）

1. Supabase → SQL Editor → 执行 `supabase/album-schema.sql`
2. Authentication → Providers → 打开 **Anonymous Sign-ins**
3. `config.js` 里填 URL / ANON，并把 `ALBUM_SYNC_ON` 改为 `true`

注意：匿名账号身份存在浏览器里，清缓存 / 换浏览器会变成新身份，云端数据失联。本地「⬇ 备份」仍是最终保险。

## 数据安全

照片、构图线条、评论、分类树全部在浏览器本地。**清浏览器数据 = 全部丢失**，请定期用相册内「⋯ → 备份」导出 json 并存到云盘。
