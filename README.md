# omp-custom

Cấu hình [omp](https://github.com/can1357/oh-my-pi) (oh-my-pi) của tôi: theme, status line, model, extension và skill. Mục đích: máy mới, hệ điều hành nào cũng chỉ cần một lệnh là có lại môi trường quen dùng — kể cả khi chưa cài omp.

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

Script tự cài omp từ nguồn chính thức (`https://omp.sh/install` hoặc `install.ps1`) nếu máy chưa có, rồi chép cấu hình, extension, skill vào `${OMP_AGENT_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}}` và plugin vào `~/.omp/sources`. File cũ được sao lưu vào `<agent-dir>/backups/<timestamp>/` trước khi ghi đè.

## Sau khi cài

1. Khôi phục đăng nhập provider (không nằm trong repo). Chọn một cách:
   - Máy cũ: `omp auth export > omp-credentials.json` (giữ file bí mật, đừng commit), máy mới: `omp auth import omp-credentials.json`.
   - Hoặc đăng nhập lại trong omp; riêng `omniroute` sẽ hỏi API key khi login.
2. Cài CLI mà một số extension cần (xem bảng bên dưới): `rtk`, `graphifyy`. Tùy chọn cài `skillspector` để quét bảo mật.
3. Chạy `omp`.

## Extension, skill & công cụ

| Thành phần | Loại | Upstream | Tác dụng | Cần cài ngoài |
|---|---|---|---|---|
| `rtk.ts` | extension | [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | Viết lại lệnh bash sang `rtk` để giảm token | `rtk` ≥ 0.23.0 trong PATH (`brew install rtk`) |
| `cli-anything/` | extension | [HKUDS/CLI-Anything](https://github.com/HKUDS/CLI-Anything) | Slash command `/cli-anything` xây CLI harness cho app GUI | — |
| `sources/ponytail/` | extension + skill | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | Lazy senior dev mode, `/ponytail*` | — |
| `skills/graphify/` | skill | [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) | `/graphify` dựng knowledge graph từ code/docs | CLI `graphifyy` (`uv tool install graphifyy`) |
| `skillspector` | CLI (ngoài repo) | [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector) | Quét bảo mật skill/extension trước khi cài hoặc sau khi nâng cấp | `uv tool install git+https://github.com/NVIDIA/SkillSpector.git` |
| `omniroute.ts` | extension | nội bộ | Provider model qua omniroute local (`127.0.0.1:20128`) | OmniRoute đang chạy |
| `herdr-omp-agent-state.ts` | extension | herdr sinh tự động | Báo trạng thái agent cho herdr | herdr |

Phiên bản/commit đã pin: xem [VERSIONS.md](VERSIONS.md). Đây là bản vendor một phần asset cần thiết (không kèm test/example); muốn bản đầy đủ thì cài từ upstream.

## Repo chứa gì

| Đường dẫn trong repo | Đích trên máy | Nội dung |
|---|---|---|
| `config/config.yml` | `<agent-dir>/config.yml` | Theme, status line, model roles, computer use, extension entries, approval mode, TUI |
| `config/models.yml` | `<agent-dir>/models.yml` | Provider/model tùy chỉnh (hiện rỗng) |
| `config/mcp.json` | `<agent-dir>/mcp.json` | MCP servers (hiện rỗng) |
| `extensions/*.ts` | `<agent-dir>/extensions/` | `omniroute`, `rtk`, `herdr` |
| `extensions/cli-anything/` | `<agent-dir>/extensions/cli-anything/` | CLI-Anything plugin + assets |
| `skills/graphify/` | `<agent-dir>/skills/graphify/` | Graphify skill |
| `sources/ponytail/` | `~/.omp/sources/ponytail/` | Ponytail plugin + skill (bản rút gọn) |
| `themes/dark-github-user-highlight-custom.json` | `<agent-dir>/themes/` | Theme tùy chỉnh |
| `install.sh` / `install.ps1` | — | Cài omp + toàn bộ cấu hình trên macOS/Linux và Windows |

Không có trong repo: session, history, credential, database (`agent.db`, `models.db`, ...) và API key thật.

## Bảo mật

- `config/models.yml` hiện không chứa provider hay key nào.
- Credential do omp quản lý trong agent dir/keychain, không nằm trong repo này.
- Trước khi push, kiểm tra `git diff` nếu vừa sửa file cấu hình.

### Quét skill/extension bằng SkillSpector

```sh
uv tool install git+https://github.com/NVIDIA/SkillSpector.git
skillspector scan extensions/cli-anything --no-llm
skillspector scan skills/graphify --no-llm
skillspector scan sources/ponytail --no-llm
```

Mặc định là static scan (`--no-llm`). Finding có thể false positive với skill chứa instruction cho agent; đọc kỹ trước khi kết luận. Quét lại sau mỗi lần nâng cấp asset từ upstream.

## Cập nhật cấu hình

- Sửa trong repo rồi chạy lại `./install.sh` (hoặc `.\install.ps1` trên Windows), hoặc
- Sửa trong agent dir, rồi copy ngược file tương ứng vào repo và commit.
- Nâng cấp extension/skill: chạy theo hướng dẫn upstream, copy lại asset vào repo, cập nhật `VERSIONS.md`.

## Ghi chú

- Không hard-code đường dẫn tuyệt đối hay home directory; các entry trong `config.yml` dùng `~`, extension top-level tự được auto-discovery.
- `extensions/herdr-omp-agent-state.ts` chỉ hoạt động khi chạy trong herdr; không dùng herdr thì bỏ qua được.
- Cần `curl` và `tar` trên macOS/Linux; PowerShell trên Windows.