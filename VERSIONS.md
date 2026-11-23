# Phiên bản đã pin (2026-11-23)

| Thành phần | Phiên bản / commit | Upstream | Cài vào |
|---|---|---|---|
| rtk | 1.2.1 (brew / winget) | https://github.com/rtk-ai/rtk | `extensions/rtk.ts` (qua `rtk init -g --agent omp`) |
| graphify | graphifyy 0.9.115 (uv tool) | https://github.com/Graphify-Labs/graphify | `skills/graphify` |
| ponytail | 5.3.3, commit `ebd8654` | https://github.com/DietrichGebert/ponytail | `extensions/ponytail` (auto-discovery) |
| CLI-Anything | commit `34f5195` | https://github.com/HKUDS/CLI-Anything | `extensions/cli-anything` (copy asset) |
| skillspector | 2.12.0 (uv tool, CLI only) | https://github.com/NVIDIA/SkillSpector | ngoài repo; dùng `skillspector scan <path> --no-llm` |

Quy trình cập nhật:

```sh
brew upgrade rtk
uv tool upgrade graphifyy
uv tool upgrade skillspector
git -C ~/path/to/ponytail-clone pull
git -C ~/path/to/CLI-Anything-clone pull
```

Sau đó copy lại asset vào repo, đọc diff trước khi commit. Ponytail trong repo chỉ giữ `package.json`, `pi-extension/`, hai file `hooks/ponytail-*.js` cần thiết, `skills/`, `AGENTS.md`, `LICENSE`; CLI-Anything chỉ giữ asset extension, không giữ toàn bộ repo.