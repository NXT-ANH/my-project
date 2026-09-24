# Kari + Jira MCP — hướng dẫn cài đặt

> Chỉ đọc file này khi cần **fallback sang MCP** (CLI không dùng MCP). Đây là hướng dẫn cho người dùng chạy,
> không phải rule khi viết testcase.

## Kari Inspector MCP

**Bước 1 — lấy PAT:** Kari Inspector → **Account Setting → Create Personal Access Token**.

**Bước 2 — Claude Code:** lưu token vào env (đừng hardcode vào config):

```bash
echo 'export KARI_PAT="kari_pat_xxxxxxxxxxxxxxxx"' >> ~/.zshrc && source ~/.zshrc

claude mcp add --transport http kari-inspector https://inspector-kari.kaopiz.com/mcp \
  --header "Authorization: Bearer ${KARI_PAT}" --scope user   # --scope user = mọi project
```

Hoặc sửa `~/.claude.json` thủ công:

```json
{ "mcpServers": { "kari-inspector": {
  "type": "http",
  "url": "https://inspector-kari.kaopiz.com/mcp",
  "headers": { "Authorization": "Bearer ${KARI_PAT}" } } } }
```

**Cursor:** `Ctrl/Cmd + Shift + P` → gõ `mcp` → **Cursor Settings: Tools & MCPs** → **New MCP Server** →
dán config trên nhưng điền PAT trực tiếp vào `Authorization` (Cursor không đọc `${KARI_PAT}`) → bật toggle.

**Kiểm tra:** Claude Code `/mcp` thấy `kari-inspector` với các tool `kari_*`. Cursor: thử "list my Kari
projects".

## Jira MCP (tùy chọn — để agent đọc task trực tiếp)

Dùng [mcp-atlassian](https://github.com/sooperset/mcp-atlassian); cần [`uv`](https://github.com/astral-sh/uv)
(cung cấp `uvx`). Lấy token: Jira → **Profile → Personal Access Tokens → Create token**.

```bash
claude mcp add mcp-atlassian uvx mcp-atlassian \
  --env JIRA_URL=https://jira.kaopiz.com \
  --env JIRA_PERSONAL_TOKEN=<your-jira-pat> --scope user
```

Hoặc JSON (Cursor / `~/.claude.json`):

```json
{ "mcpServers": { "mcp-atlassian": {
  "command": "uvx", "args": ["mcp-atlassian"],
  "env": { "JIRA_URL": "https://jira.kaopiz.com", "JIRA_PERSONAL_TOKEN": "<your-jira-pat>" } } } }
```

> IDE báo không tìm thấy `uvx` → thay `command` bằng đường dẫn đầy đủ (`which uvx`).

## Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| `401 Unauthorized` | Sai hoặc thiếu PAT | `echo $KARI_PAT` để kiểm tra |
| `Bearer ` (trống) | Biến env chưa export | Thêm `export` vào `~/.zshrc`, restart terminal |
| Không thấy tools | Server chưa connect | Kiểm tra URL + PAT, `/mcp` reconnect |
| `Kari API failed (401)` | PAT hết hạn | Tạo PAT mới |
| `Kari API failed (403)` | PAT thiếu quyền | Kiểm tra phân quyền trong Kari settings |
