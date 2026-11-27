#!/usr/bin/env sh
# Cài omp-custom trên macOS/Linux (kể cả WSL): cài omp nếu chưa có, rồi chép cấu hình.
# Dùng được cả khi clone repo lẫn khi chạy qua pipe:
#   curl -fsSL https://raw.githubusercontent.com/quangtiss/omp-custom/main/install.sh | sh
set -eu

REPO_SLUG="quangtiss/omp-custom"
REF="main"
TARBALL="https://codeload.github.com/$REPO_SLUG/tar.gz/refs/heads/$REF"

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    echo "Windows: dùng PowerShell thay vì sh:"
    echo "  irm https://raw.githubusercontent.com/quangtiss/omp-custom/main/install.ps1 | iex"
    exit 1
    ;;
esac

# curl hoặc wget; một số distro tối giản chỉ có một trong hai.
fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    echo "Cần curl hoặc wget để tải xuống." >&2
    return 1
  fi
}

CLEANUP_DIR=""
cleanup() {
  if [ -n "$CLEANUP_DIR" ]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT HUP INT TERM

# 1. Xác định thư mục repo (checkout hoặc tải tarball khi chạy qua pipe).
REPO_DIR=""
if [ -n "${OMP_CUSTOM_DIR:-}" ] && [ -f "$OMP_CUSTOM_DIR/config/config.yml" ]; then
  REPO_DIR="$OMP_CUSTOM_DIR"
else
  case "${0:-}" in
    */*) HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)" ;;
    *) HERE="" ;;
  esac
  if [ -n "$HERE" ] && [ -f "$HERE/config/config.yml" ]; then
    REPO_DIR="$HERE"
  fi
fi

if [ -z "$REPO_DIR" ]; then
  echo "Đang tải omp-custom ($REF)..."
  CLEANUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/omp-custom.XXXXXX")"
  fetch "$TARBALL" | tar -xz -C "$CLEANUP_DIR"
  # GitHub tarball bọc trong một thư mục; tìm nó thay vì dựa vào --strip-components (busybox tar không có).
  REPO_DIR="$(find "$CLEANUP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [ -z "$REPO_DIR" ]; then
    echo "Giải nén thất bại." >&2
    exit 1
  fi
fi

# 2. Cài omp nếu máy chưa có.
if ! command -v omp >/dev/null 2>&1; then
  echo "Chưa có omp, đang cài từ https://omp.sh/install ..."
  fetch https://omp.sh/install | sh
  PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
  export PATH
fi

if ! command -v omp >/dev/null 2>&1; then
  echo "Cài omp xong nhưng không thấy lệnh 'omp' trong PATH."
  echo "Mở terminal mới rồi chạy lại script này."
  exit 1
fi

# 3. Chép cấu hình vào agent dir.
AGENT_DIR="${OMP_AGENT_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$AGENT_DIR/backups/$STAMP"

mkdir -p "$AGENT_DIR/extensions" "$AGENT_DIR/themes"

install_file() {
  SRC="$1"
  DEST="$2"
  REL="$3"
  if [ -e "$DEST" ] && ! cmp -s "$SRC" "$DEST"; then
    mkdir -p "$BACKUP_DIR/$(dirname "$REL")"
    cp -p "$DEST" "$BACKUP_DIR/$REL"
    echo "backup:    $REL"
  fi
  mkdir -p "$(dirname "$DEST")"
  cp "$SRC" "$DEST"
  echo "installed: $REL"
}

install_tree() {
  SRC_ROOT="$1"
  DEST_ROOT="$2"
  PREFIX="$3"
  find "$SRC_ROOT" -type f | while IFS= read -r f; do
    rel="${f#"$SRC_ROOT"/}"
    install_file "$f" "$DEST_ROOT/$rel" "$PREFIX/$rel"
  done
}

install_file "$REPO_DIR/config/config.yml" "$AGENT_DIR/config.yml" config.yml
install_file "$REPO_DIR/config/models.yml" "$AGENT_DIR/models.yml" models.yml
install_file "$REPO_DIR/config/mcp.json" "$AGENT_DIR/mcp.json" mcp.json

for f in "$REPO_DIR"/extensions/*; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  if [ -d "$f" ]; then
    install_tree "$f" "$AGENT_DIR/extensions/$name" "extensions/$name"
  else
    install_file "$f" "$AGENT_DIR/extensions/$name" "extensions/$name"
  fi
done

if [ -d "$REPO_DIR/skills" ]; then
  install_tree "$REPO_DIR/skills" "$AGENT_DIR/skills" skills
fi

for f in "$REPO_DIR"/themes/*.json; do
  [ -e "$f" ] && install_file "$f" "$AGENT_DIR/themes/$(basename "$f")" "themes/$(basename "$f")"
done

chmod 600 "$AGENT_DIR/config.yml" "$AGENT_DIR/models.yml" 2>/dev/null || true

if [ -d "$BACKUP_DIR" ]; then
  echo "Bản cũ đã sao lưu tại: $BACKUP_DIR"
fi

# 4. CLI phụ thuộc. Bỏ qua bằng OMP_CUSTOM_SKIP_DEPS=1.
if [ -z "${OMP_CUSTOM_SKIP_DEPS:-}" ]; then
  if command -v rtk >/dev/null 2>&1; then
    echo "rtk: đã có ($(rtk --version 2>/dev/null | head -1))"
  elif command -v brew >/dev/null 2>&1; then
    echo "Đang cài rtk (rewrite lệnh để tiết kiệm token)..."
    if brew install rtk; then
      command -v rtk >/dev/null 2>&1 || \
        echo "Đã cài rtk nhưng lệnh chưa có trong PATH — thêm '$(brew --prefix)/bin' vào PATH rồi mở terminal mới."
    else
      echo "Cài rtk thất bại — cài tay: https://github.com/rtk-ai/rtk"
    fi
  else
    echo "Thiếu rtk: cài bằng 'brew install rtk' hoặc https://github.com/rtk-ai/rtk"
  fi

  if command -v graphify >/dev/null 2>&1; then
    echo "graphifyy: đã có"
  elif command -v uv >/dev/null 2>&1; then
    echo "Đang cài graphifyy (skill /graphify)..."
    if uv tool install graphifyy; then
      command -v graphify >/dev/null 2>&1 || \
        echo "Đã cài nhưng '$HOME/.local/bin' chưa có trong PATH — thêm vào rồi mở terminal mới."
    else
      echo "Cài graphifyy thất bại — chạy tay: uv tool install graphifyy"
    fi
  else
    echo "Thiếu graphifyy: cài bằng 'uv tool install graphifyy' (https://docs.astral.sh/uv/)"
  fi
fi

# 5. desktop-input: build từ repo, không phải dependency ngoài, nên không nằm trong cổng SKIP_DEPS.
# Chỉ macOS, vì CGEvent và Vision không có trên Linux/Windows.
if [ "$(uname -s 2>/dev/null)" = "Darwin" ] && [ -d "$REPO_DIR/tools/mac" ]; then
  if command -v swiftc >/dev/null 2>&1; then
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    for tool in vn-type ocr; do
      if [ ! -x "$BIN_DIR/$tool" ] || [ "$REPO_DIR/tools/mac/$tool.swift" -nt "$BIN_DIR/$tool" ]; then
        if swiftc -O "$REPO_DIR/tools/mac/$tool.swift" -o "$BIN_DIR/$tool" 2>/dev/null; then
          echo "built:     $tool"
        else
          echo "Build $tool thất bại — cần Xcode Command Line Tools: xcode-select --install"
        fi
      else
        echo "$tool: đã có"
      fi
    done
  else
    echo "Thiếu swiftc (Xcode Command Line Tools) — bỏ qua vn-type và ocr."
  fi
fi

echo "Xong. Chạy 'omp' để kiểm tra."
