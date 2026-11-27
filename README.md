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

Script tự cài omp từ nguồn chính thức (`https://omp.sh/install` hoặc `install.ps1`) nếu máy chưa có, rồi chép cấu hình, extension, skill vào `${OMP_AGENT_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}}`. File cũ được sao lưu vào `<agent-dir>/backups/<timestamp>/` trước khi ghi đè.

### Yêu cầu theo hệ điều hành

| Hệ điều hành | Script | Cần có sẵn |
|---|---|---|
| macOS | `install.sh` | `curl` hoặc `wget`, `tar` (có sẵn) |
| Linux | `install.sh` | `curl` hoặc `wget`, `tar`; Alpine: `apk add libstdc++ libgcc` (binary omp cần) |
| WSL | `install.sh` | như Linux |
| Windows | `install.ps1` (PowerShell 5.1+) | không cần gì thêm; dùng `winget` nếu có để cài `rtk` |

`install.sh` từ chối chạy trong Git Bash/MSYS2/Cygwin và chỉ sang `install.ps1`. Không có đường dẫn tuyệt đối hay `~` nào trong cấu hình, nên cùng một bộ file dùng được cho cả ba hệ.

## Sau khi cài

1. Khôi phục đăng nhập provider (không nằm trong repo). Chọn một cách:
   - Máy cũ: `omp auth export > omp-credentials.json` (giữ file bí mật, đừng commit), máy mới: `omp auth import omp-credentials.json`.
   - Hoặc đăng nhập lại trong omp; riêng `omniroute` sẽ hỏi API key khi login.
2. CLI phụ thuộc được cài tự động khi có sẵn trình quản lý gói: `rtk` qua `brew` (macOS/Linux) hoặc `winget` (Windows), `graphifyy` qua `uv`. Nếu máy thiếu `brew`/`winget`/`uv`, script in hướng dẫn cài tay. Bỏ qua bước này bằng `OMP_CUSTOM_SKIP_DEPS=1`. Tùy chọn cài `skillspector` để quét bảo mật.
3. Trên macOS, nếu có Xcode CLT thì `install.sh` build `vn-type`/`ocr` vào `~/.local/bin`; lần đầu dùng `vn-type` phải cấp quyền Accessibility cho app chạy `omp`.
4. Tùy chọn: `omp tiny-models download lfm2.5-230m` (~214 MB) để `title.generator: tiny` sinh tiêu đề session bằng model local thay vì im lặng bỏ qua.
5. Chạy `omp`.

## Extension, skill & công cụ

| Thành phần | Loại | Upstream | Tác dụng | Cần cài ngoài |
|---|---|---|---|---|
| `rtk.ts` | extension | [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | Viết lại lệnh bash sang `rtk` để giảm token | `rtk` ≥ 0.23.0 trong PATH — script tự cài qua brew/winget |
| `cli-anything/` | extension | [HKUDS/CLI-Anything](https://github.com/HKUDS/CLI-Anything) | Slash command `/cli-anything` xây CLI harness cho app GUI | — |
| `extensions/ponytail/` | extension + skill | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | Lazy senior dev mode, `/ponytail*` | — |
| `skills/graphify/` | skill | [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) | `/graphify` dựng knowledge graph từ code/docs | CLI `graphifyy` — script tự cài qua uv |
| `skills/desktop-input/` | skill + CLI | nội bộ | `vn-type` gõ từng phím (tiếng Việt được), `ocr` đọc toạ độ chữ trên màn hình cho app canvas | macOS + Xcode CLT; `install.sh` tự build vào `~/.local/bin`, lần đầu cần cấp quyền Accessibility |
| `skillspector` | CLI (ngoài repo) | [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector) | Quét bảo mật skill/extension trước khi cài hoặc sau khi nâng cấp | `uv tool install git+https://github.com/NVIDIA/SkillSpector.git` |
| `omniroute.ts` | extension | nội bộ | Provider model qua omniroute local (`127.0.0.1:20128`) | OmniRoute đang chạy |
| `herdr-omp-agent-state.ts` | extension | herdr sinh tự động | Báo trạng thái agent cho herdr | herdr |

Phiên bản/commit đã pin: xem [VERSIONS.md](VERSIONS.md). Đây là bản vendor một phần asset cần thiết (không kèm test/example); muốn bản đầy đủ thì cài từ upstream.

## Repo chứa gì

| Đường dẫn trong repo | Đích trên máy | Nội dung |
|---|---|---|
| `config/config.yml` | `<agent-dir>/config.yml` | Theme, status line, model roles, computer use, approval mode, TUI; không có entry extension vì auto-discovery |
| `config/models.yml` | `<agent-dir>/models.yml` | Override tên model hiển thị thành `provider/id` |
| `config/mcp.json` | `<agent-dir>/mcp.json` | MCP servers (hiện rỗng) |
| `extensions/*.ts` | `<agent-dir>/extensions/` | `omniroute`, `rtk`, `herdr` |
| `extensions/cli-anything/` | `<agent-dir>/extensions/cli-anything/` | CLI-Anything plugin + assets |
| `skills/graphify/` | `<agent-dir>/skills/graphify/` | Graphify skill |
| `skills/desktop-input/` | `<agent-dir>/skills/desktop-input/` | Skill gõ từng phím + OCR toạ độ (macOS) |
| `tools/mac/*.swift` | `~/.local/bin/{vn-type,ocr}` | Nguồn 2 CLI, `install.sh` build bằng `swiftc` |
| `extensions/ponytail/` | `<agent-dir>/extensions/ponytail/` | Ponytail plugin + skill (bản rút gọn) |
| `themes/dark-github-user-highlight-custom.json` | `<agent-dir>/themes/` | Theme tùy chỉnh |
| `install.sh` / `install.ps1` | — | Cài omp + toàn bộ cấu hình trên macOS/Linux và Windows |

Không có trong repo: session, history, credential, database (`agent.db`, `models.db`, ...) và API key thật.

## Tiết kiệm token (đang bật)

| Cơ chế | Ở đâu | Ghi chú |
|---|---|---|
| Shell output minimizer | core omp (mặc định) | Nén output bash; dấu `Σ <bytes>` trong kết quả là dấu hiệu đang chạy |
| Rewrite lệnh sang `rtk` | `extensions/rtk.ts` | `git status`, `ls`, `grep`, `cat→read`, `find`, `diff`, `test`, `log`… |
| `read.summarize` | core (mặc định) | Gấp thân hàm/comment khi file ≥ 100 dòng |
| Prompt cache | provider | Giữ nguyên prefix system prompt giữa các lượt |
| Model rẻ cho việc phụ | `modelRoles.task` / `smol` | Subagent, tiêu đề, việc nhỏ chạy model flash |
| `title.generator: tiny` | `config.yml` | Chỉ chạy khi đã tải tiny model local |
| Status line có token/cost | `config.yml` | `token_total`, `cost`, `context_pct` để thấy chi phí ngay |

Đo lại bất cứ lúc nào:

```sh
rtk gain        # số lệnh đã rewrite + % token tiết kiệm
omp stats       # dashboard token/cache/cost theo model
```

Baseline đo trên máy này (2026-11-23, omp 19.1.1): rtk 267 lệnh, tiết kiệm 40.6K token (58.2%); `omp stats` 477 request, cache hit 94.2%, tổng cost $0.046. Số này chỉ để tham chiếu, không phải cam kết.

`bashInterceptor.enabled` để tắt: rtk đã rewrite lệnh, bật thêm sẽ chặn hẳn `cat`/`grep`/`find` thành tool native và làm mất các cờ lệnh người dùng gõ.

## Bảo mật

- `config/models.yml` không chứa API key; chỉ chứa override tên model.
- Credential do omp quản lý trong agent dir/keychain, không nằm trong repo này.
- Trước khi push, kiểm tra `git diff` nếu vừa sửa file cấu hình.

### Quét skill/extension bằng SkillSpector

```sh
uv tool install git+https://github.com/NVIDIA/SkillSpector.git
skillspector scan extensions/cli-anything --no-llm
skillspector scan skills/graphify --no-llm
skillspector scan extensions/ponytail --no-llm
```

Mặc định là static scan (`--no-llm`). Finding có thể false positive với skill chứa instruction cho agent; đọc kỹ trước khi kết luận. Quét lại sau mỗi lần nâng cấp asset từ upstream.

## Cập nhật cấu hình

- Sửa trong repo rồi chạy lại `./install.sh` (hoặc `.\install.ps1` trên Windows), hoặc
- Sửa trong agent dir, rồi copy ngược file tương ứng vào repo và commit.
- Nâng cấp extension/skill: chạy theo hướng dẫn upstream, copy lại asset vào repo, cập nhật `VERSIONS.md`.

## Ghi chú

- Không hard-code đường dẫn tuyệt đối hay home directory: mọi extension nằm trong `<agent-dir>/extensions` và tự được auto-discovery, nên `config.yml` không có entry đường dẫn nào (chạy được trên mọi OS).
- `config/models.yml` chỉ override tên của model đang có trong catalog; model mới thêm sau này sẽ hiện tên gốc cho tới khi bổ sung override.
- `extensions/herdr-omp-agent-state.ts` chỉ hoạt động khi chạy trong herdr; không dùng herdr thì bỏ qua được.
- `install.sh` chỉ dùng POSIX sh + lệnh chuẩn (không cần bash/zsh/brew); `models.yml` chỉ override tên hiển thị nên không phụ thuộc OS.
