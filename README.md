# 🔍 zenrows-skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-Skill-6366F1)](https://clawhub.com)
[![shellcheck](https://github.com/Penguin-Life/zenrows-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/Penguin-Life/zenrows-skill/actions/workflows/ci.yml)

**Web scraping skill for [OpenClaw](https://github.com/openclaw/openclaw) agents — powered by [ZenRows](https://www.zenrows.com/).**

When `web_fetch` fails due to anti-bot protection, JS-rendered content, or geo-restrictions, ZenRows handles it:

- **Anti-bot bypass** — Cloudflare, DataDome, PerimeterX, etc.
- **JavaScript rendering** — SPAs, dynamic content, lazy-loaded pages
- **CAPTCHA solving** — Automatic CAPTCHA resolution
- **Proxy rotation** — Residential proxies from 190+ countries
- **Output formats** — HTML, Markdown, Plaintext, PDF, Screenshots

---

## Quick Start (OpenClaw)

1. Install:
   ```bash
   clawhub install Penguin-Life/zenrows-skill
   ```

2. Add your API key to `openclaw.json`:
   ```json
   {
     "env": {
       "vars": {
         "ZENROWS_API_KEY": "your-api-key-here"
       }
     }
   }
   ```
   Get a key at [zenrows.com](https://www.zenrows.com/) (free tier: 1,000 credits).

3. Restart OpenClaw:
   ```bash
   openclaw gateway restart
   ```

4. Ask your agent:
   > "Fetch https://protected-site.com as markdown"

---

## Standalone CLI

```bash
# Basic fetch
./zenrows/scripts/zenrows.sh "https://example.com"

# Markdown output (ideal for LLM context)
./zenrows/scripts/zenrows.sh "https://example.com" --markdown

# Auto mode (ZenRows picks optimal anti-bot strategy)
./zenrows/scripts/zenrows.sh "https://protected-site.com" --auto

# JS rendering for SPAs
./zenrows/scripts/zenrows.sh "https://spa-app.com" --js --wait-for ".content"

# Extract structured data with CSS selectors
./zenrows/scripts/zenrows.sh "https://news.site.com" \
  --css '{"title":"h1","body":".article-body"}'

# Specific country proxy
./zenrows/scripts/zenrows.sh "https://geo-restricted.com" --premium --country us
```

### Example Output

```
$ ./zenrows.sh "https://example.com" --markdown

# Example Domain

This domain is for use in illustrative examples in documents.
You may use this domain in literature without prior coordination...
```

---

## When to Use ZenRows vs web_fetch

```
Need web content?
├── Try web_fetch first (free)
│   ├── ✅ Success → done
│   └── ❌ Blocked / empty / broken
│       ├── Static site, basic protection → zenrows (1 credit)
│       ├── JS-heavy SPA → zenrows --js (5 credits)
│       ├── Strong anti-bot → zenrows --auto (variable)
│       └── Structured extraction → zenrows --css / --autoparse
└── Need markdown/text for LLM? → zenrows --markdown / --text
```

## Credit Costs

| Config | Credits |
|--------|---------|
| Basic (HTML only) | 1 |
| JS rendering (`--js`) | 5 |
| Premium proxies (`--premium`) | 5 |
| JS + Premium | 10 |
| CAPTCHA solving (`--captcha`) | +25 |
| Auto mode (`--auto`) | Variable |

## CLI Options

| Option | Description |
|--------|-------------|
| `--auto` | Adaptive Stealth Mode |
| `--js` | Enable JS rendering |
| `--premium` | Residential proxies |
| `--country <CC>` | Proxy country (implies --premium) |
| `--markdown` | Markdown output |
| `--text` | Plaintext output |
| `--pdf` | PDF output |
| `--autoparse` | Auto-extract structured data |
| `--css '<json>'` | CSS selector extraction |
| `--wait <ms>` | Wait fixed ms (requires --js) |
| `--wait-for <sel>` | Wait for CSS selector (requires --js) |
| `--captcha` | Auto-solve CAPTCHAs |
| `--screenshot` | Base64 screenshot |
| `--json` | JSON response with headers |
| `-o <file>` | Write to file |
| `-v` | Verbose mode |

See [`zenrows/SKILL.md`](zenrows/SKILL.md) for the full API parameter reference.

---

## Project Structure

```
zenrows-skill/
├── skill.json              # Package manifest
├── README.md               # This file
├── zenrows/
│   ├── SKILL.md            # Full agent instructions + API reference
│   └── scripts/
│       └── zenrows.sh      # CLI wrapper
└── .github/workflows/
    └── ci.yml              # shellcheck + smoke tests
```

## License

[MIT](LICENSE)

---

Built with 🐧 by [Penguin-Life](https://github.com/Penguin-Life)
