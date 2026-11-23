#!/usr/bin/env bash
# Chép cấu hình omp từ repo này vào $HOME/.omp/agent.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="${OMP_AGENT_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$AGENT_DIR/backups/$STAMP"

if ! command -v omp >/dev/null 2>&1; then
  echo "Cảnh báo: chưa thấy lệnh 'omp' trong PATH. Cài omp trước rồi chạy lại script nếu cần."
fi

mkdir -p "$AGENT_DIR/extensions" "$AGENT_DIR/themes"

install_file() {
  local src="$1"
  local rel="$2"
  local dest="$AGENT_DIR/$rel"
  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -p "$dest" "$BACKUP_DIR/$rel"
    echo "backup:    $rel"
  fi
  cp "$src" "$dest"
  echo "installed: $rel"
}

install_file "$REPO_DIR/config/config.yml" config.yml
install_file "$REPO_DIR/config/models.yml" models.yml
install_file "$REPO_DIR/config/mcp.json" mcp.json

for f in "$REPO_DIR"/extensions/*.ts; do
  install_file "$f" "extensions/$(basename "$f")"
done
for f in "$REPO_DIR"/themes/*.json; do
  install_file "$f" "themes/$(basename "$f")"
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