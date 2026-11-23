# omp-config

Cấu hình [omp](https://github.com/can1357/oh-my-pi) (oh-my-pi) của tôi. Mục đích: cài omp trên máy mới, clone repo này, chạy `install.sh` là có lại giao diện, model, extension và theme quen dùng.

## Yêu cầu

- Đã cài omp từ trang chính thức (`omp --version` chạy được).
- `git`, `bash`.

## Cài trên máy mới

```bash
git clone https://github.com/quangtiss/omp-config.git
cd omp-config
./install.sh
```

Script chép file vào `${OMP_AGENT_DIR:-$HOME/.omp/agent}`, tự sao lưu file cũ vào `~/.omp/agent/backups/<timestamp>/` trước khi ghi đè.

Sau khi cài:

1. Mở `~/.omp/agent/models.yml`, điền `"apiKey"` cho provider `vector`.
2. Khôi phục đăng nhập provider (không nằm trong repo). Chọn một cách:
   - Máy cũ: `omp auth export > omp-credentials.json` (giữ file này bí mật, đừng commit), máy mới: `omp auth import omp-credentials.json`.
   - Hoặc đăng nhập lại trong omp; riêng `omniroute` sẽ hỏi API key khi login.
3. Chạy `omp`.

## Repo chứa gì

| Đường dẫn trong repo | Đích trên máy | Nội dung |
|---|---|---|
| `config/config.yml` | `~/.omp/agent/config.yml` | Theme, status line, model roles, approval mode, TUI |
| `config/models.yml` | `~/.omp/agent/models.yml` | Provider/model tùy chỉnh (`vector`, API key để trống) |
| `config/mcp.json` | `~/.omp/agent/mcp.json` | MCP servers (hiện rỗng) |
| `extensions/omniroute.ts` | `~/.omp/agent/extensions/omniroute.ts` | Provider động cho omniroute (`127.0.0.1:20128`) |
| `extensions/herdr-omp-agent-state.ts` | `~/.omp/agent/extensions/` | Báo trạng thái agent cho herdr; herdr tự ghi đè khi cài lại |
| `themes/dark-github-user-highlight-custom.json` | `~/.omp/agent/themes/` | Theme tùy chỉnh |

Không có trong repo: session, history, auth token, database (`agent.db`, `models.db`, ...) và API key.

## Bảo mật

- `config/models.yml` được commit với `apiKey` rỗng. Điền key trên máy, **không** commit key thật.
- Key và token đăng nhập do omp quản lý ở `auth.json`/keychain, không nằm trong repo này.
- Repo public: kiểm tra `git diff` trước khi push nếu có sửa file cấu hình.

## Cập nhật cấu hình

- Sửa trong repo rồi chạy lại `./install.sh`, hoặc
- Sửa trong `~/.omp/agent`, sau đó copy ngược file tương ứng vào repo và commit.

## Ghi chú

- Đường dẫn extension trong `config.yml` dùng `~`, không hard-code home directory.
- `extensions/herdr-omp-agent-state.ts` chỉ hoạt động khi chạy trong herdr; nếu không dùng herdr có thể bỏ qua file này.