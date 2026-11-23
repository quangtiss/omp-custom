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
    echo "Windows: chạy install.ps1 trong PowerShell thay vì install.sh."
    exit 1
    ;;
esac

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
  curl -fsSL "$TARBALL" | tar -xz -C "$CLEANUP_DIR" --strip-components=1
  REPO_DIR="$CLEANUP_DIR"
fi

# 2. Cài omp nếu máy chưa có.
if ! command -v omp >/dev/null 2>&1; then
  echo "Chưa có omp, đang cài từ https://omp.sh/install ..."
  curl -fsSL https://omp.sh/install | sh
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
SOURCES_DIR="$HOME/.omp/sources"
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

if [ -d "$REPO_DIR/sources/ponytail" ]; then
  install_tree "$REPO_DIR/sources/ponytail" "$SOURCES_DIR/ponytail" sources/ponytail
fi

for f in "$REPO_DIR"/themes/*.json; do
  [ -e "$f" ] && install_file "$f" "$AGENT_DIR/themes/$(basename "$f")" "themes/$(basename "$f")"
done

chmod 600 "$AGENT_DIR/config.yml" "$AGENT_DIR/models.yml" 2>/dev/null || true

if [ -d "$BACKUP_DIR" ]; then
  echo "Bản cũ đã sao lưu tại: $BACKUP_DIR"
fi

if grep -q 'PASTE_VECTOR_API_KEY_HERE' "$AGENT_DIR/models.yml" 2>/dev/null; then
  echo
  echo "Lưu ý: provider 'vector' trong $AGENT_DIR/models.yml đang dùng API key placeholder."
  echo "Mở file đó, thay PASTE_VECTOR_API_KEY_HERE bằng key thật rồi khởi động omp."
  echo "Không commit key thật vào repo."
fi

echo "Xong. Chạy 'omp' để kiểm tra."