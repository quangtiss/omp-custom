# Phiên bản đã pin (2026-11-23)

| Thành phần | Phiên bản / commit | Upstream | Cài vào |
|---|---|---|---|
| rtk | 1.2.1 (brew) | https://github.com/rtk-ai/rtk | `extensions/rtk.ts` (qua `rtk init -g --agent omp`) |
| graphify | graphifyy 0.9.115 (uv tool) | https://github.com/Graphify-Labs/graphify | `skills/graphify` |
| ponytail | 5.3.3, commit `ebd8654` | https://github.com/DietrichGebert/ponytail | `sources/ponytail`, load qua entry trong `config.yml` |
| CLI-Anything | commit `34f5195` | https://github.com/HKUDS/CLI-Anything | `extensions/cli-anything` (copy asset) |

Quy trình cập nhật:

```sh
brew upgrade rtk
uv tool upgrade graphifyy
git -C ~/.omp/sources/ponytail pull
git -C ~/.omp/sources/CLI-Anything pull
```

Sau đó copy lại asset vào repo, đọc diff trước khi commit. Ponytail trong repo chỉ giữ `package.json`, `pi-extension/`, hai file `hooks/ponytail-*.js` cần thiết, `skills/`, `AGENTS.md`, `LICENSE`; CLI-Anything chỉ giữ asset extension, không giữ toàn bộ repo.