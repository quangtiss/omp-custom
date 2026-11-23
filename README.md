# omp-custom

Cấu hình [omp](https://github.com/can1357/oh-my-pi) (oh-my-pi) của tôi: theme, status line, model, extension. Mục đích: máy mới, hệ điều hành nào cũng chỉ cần một lệnh là có lại môi trường quen dùng — kể cả khi chưa cài omp.

## Cài một lệnh

**macOS / Linux / WSL**

```sh
curl -fsSL https://raw.githubusercontent.com/quangtiss/omp-custom/main/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/quangtiss/omp-custom/main/install.ps1 | iex
```

**Từ bản clone**

```sh
git clone https://github.com/quangtiss/omp-custom.git
cd omp-custom
./install.sh          # Windows: .\install.ps1
```

Script tự cài omp từ nguồn chính thức (`https://omp.sh/install` hoặc `install.ps1`) nếu máy chưa có, rồi chép cấu hình vào `${OMP_AGENT_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}}`. File cũ được sao lưu vào `<agent-dir>/backups/<timestamp>/` trước khi ghi đè.

## Sau khi cài

1. Mở `<agent-dir>/models.yml`, thay `PASTE_VECTOR_API_KEY_HERE` bằng API key của provider `vector`.
2. Khôi phục đăng nhập provider (không nằm trong repo). Chọn một cách:
   - Máy cũ: `omp auth export > omp-credentials.json` (giữ file bí mật, đừng commit), máy mới: `omp auth import omp-credentials.json`.
   - Hoặc đăng nhập lại trong omp; riêng `omniroute` sẽ hỏi API key khi login.
3. Chạy `omp`.

## Repo chứa gì

| Đường dẫn trong repo | Đích trên máy | Nội dung |
|---|---|---|
| `config/config.yml` | `<agent-dir>/config.yml` | Theme, status line, model roles, approval mode, TUI |
| `config/models.yml` | `<agent-dir>/models.yml` | Provider/model tùy chỉnh (`vector`, API key là placeholder) |
| `config/mcp.json` | `<agent-dir>/mcp.json` | MCP servers (hiện rỗng) |
| `extensions/omniroute.ts` | `<agent-dir>/extensions/` | Provider động cho omniroute (`127.0.0.1:20128`) |
| `extensions/herdr-omp-agent-state.ts` | `<agent-dir>/extensions/` | Báo trạng thái agent cho herdr; herdr tự ghi đè khi cài lại |
| `themes/dark-github-user-highlight-custom.json` | `<agent-dir>/themes/` | Theme tùy chỉnh |
| `install.sh` / `install.ps1` | — | Cài omp + cấu hình trên macOS/Linux và Windows |

Không có trong repo: session, history, credential, database (`agent.db`, `models.db`, ...) và API key thật.

## Bảo mật

- `config/models.yml` chỉ chứa placeholder; không commit key thật.
- Credential do omp quản lý trong agent dir/keychain, không nằm trong repo này.
- Trước khi push, kiểm tra `git diff` nếu vừa sửa file cấu hình.

## Cập nhật cấu hình

- Sửa trong repo rồi chạy lại `./install.sh` (hoặc `.\install.ps1` trên Windows), hoặc
- Sửa trong agent dir, rồi copy ngược file tương ứng vào repo và commit.

## Ghi chú

- Không hard-code đường dẫn tuyệt đối hay home directory; `config.yml` dùng auto-discovery cho `extensions/`.
- Extension `herdr-omp-agent-state.ts` chỉ hoạt động khi chạy trong herdr; không dùng herdr thì bỏ qua được.
- Cần `curl` và `tar` trên macOS/Linux; PowerShell trên Windows.