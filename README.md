# ZenRows Skill for OpenClaw

A ready-to-use [OpenClaw](https://github.com/openclaw/openclaw) skill that integrates the [ZenRows Universal Scraper API](https://www.zenrows.com/) for reliable web content extraction — even from sites protected by Cloudflare, DataDome, and other anti-bot systems.

## What It Does

ZenRows acts as a smart proxy layer between your agent and the web. When `web_fetch` fails due to anti-bot protection, JavaScript-rendered content, or geo-restrictions, ZenRows handles:

- **Anti-bot bypass** — Cloudflare, DataDome, PerimeterX, etc.
- **JavaScript rendering** — SPAs, dynamic content, lazy-loaded pages
- **CAPTCHA solving** — Automatic CAPTCHA resolution
- **Proxy rotation** — Residential proxies from 190+ countries
- **Output formats** — HTML, Markdown, Plaintext, PDF, Screenshots

## Quick Start

### 1. Install the Skill

Copy the `zenrows/` folder into your OpenClaw skills directory:

```bash
cp -r zenrows/ ~/openclaw/skills/zenrows/
```

Or clone this repo and symlink:

```bash
git clone https://github.com/Penguin-Life/zenrows-skill.git
ln -s "$(pwd)/zenrows-skill/zenrows" ~/openclaw/skills/zenrows
```

### 2. Configure Your API Key

Add your ZenRows API key to `openclaw.json` under `env.vars`:

```json
{
  "env": {
    "vars": {
      "ZENROWS_API_KEY": "your-api-key-here"
    }
  }
}
```

Get your API key at [zenrows.com](https://www.zenrows.com/) (free tier available with 1,000 credits).

### 3. Restart OpenClaw

```bash
openclaw gateway restart
```

The skill will be auto-discovered on next session.

## Usage

### Shell Script (Recommended for Agents)

The bundled `scripts/zenrows.sh` wraps the full API into a simple CLI:

```bash
# Basic fetch
scripts/zenrows.sh "https://example.com"

# Get markdown output (ideal for LLM context)
scripts/zenrows.sh "https://example.com" --markdown

# Auto mode — ZenRows picks the optimal anti-bot strategy
scripts/zenrows.sh "https://protected-site.com" --auto

# JS rendering for SPAs
scripts/zenrows.sh "https://spa-app.com" --js --wait-for ".content-loaded"

# Extract structured data with CSS selectors
scripts/zenrows.sh "https://news.site.com/article" \
  --css '{"title":"h1","body":".article-body","author":".byline"}'

# Fetch from a specific country
scripts/zenrows.sh "https://geo-restricted.com" --premium --country us

# Plaintext output
scripts/zenrows.sh "https://example.com" --text
```

### Direct API (curl)

```bash
# Minimal request
curl "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com"

# With JS rendering + markdown output
curl "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com&js_render=true&response_type=markdown"

# Adaptive Stealth Mode
curl "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com&mode=auto"
```

## Script Options Reference

| Option | Description |
|--------|-------------|
| `--auto` | Adaptive Stealth Mode — auto-selects optimal config |
| `--js` | Enable JavaScript rendering (headless browser) |
| `--premium` | Use residential/premium proxies |
| `--country <CC>` | Proxy from specific country (2-letter code, implies `--premium`) |
| `--markdown` | Return content as Markdown |
| `--text` | Return content as plaintext |
| `--pdf` | Return content as PDF |
| `--autoparse` | Auto-extract structured data |
| `--css '<json>'` | CSS selector extraction (JSON object) |
| `--wait <ms>` | Wait fixed milliseconds (requires `--js`) |
| `--wait-for <sel>` | Wait for CSS selector to appear (requires `--js`) |
| `--block <types>` | Block resources: `stylesheet,image,media,font,script` |
| `--session <id>` | Reuse same IP across requests (requires `--premium`) |
| `--captcha` | Auto-solve CAPTCHAs (implies `--js --premium`) |
| `--screenshot` | Return base64 screenshot (implies `--js`) |
| `--json` | Wrap response in JSON with headers/status |
| `--device <d>` | `desktop` or `mobile` user-agent (implies `--js`) |
| `--post <body>` | Send POST request with body |
| `--header <H:V>` | Add custom header (repeatable) |
| `-o <file>` | Write output to file |
| `-v` | Verbose mode |

## Credit Costs

| Configuration | Credits |
|--------------|---------|
| Basic (HTML only) | 1 |
| JS rendering (`--js`) | 5 |
| Premium proxies (`--premium`) | 5 |
| JS + Premium | 10 |
| CAPTCHA solving (`--captcha`) | +25 |
| Auto mode (`--auto`) | Variable (billed for what works) |

## When to Use ZenRows vs web_fetch

```
Need web content?
├── Try web_fetch first (free)
│   ├── ✅ Success → done
│   └── ❌ Blocked / empty / broken
│       ├── Static site, basic protection → zenrows (1 credit)
│       ├── JS-heavy SPA → zenrows --js (5 credits)
│       ├── Strong anti-bot → zenrows --auto (auto-optimized)
│       └── Need structured extraction → zenrows --css or --autoparse
└── Need markdown/text for LLM? → zenrows --markdown / --text
```

## Skill Structure

```
zenrows/
├── SKILL.md              # Full skill instructions (auto-loaded by OpenClaw)
└── scripts/
    └── zenrows.sh        # CLI wrapper for the ZenRows API
```

## API Documentation

For the complete ZenRows API reference, see:
- [ZenRows API Docs](https://docs.zenrows.com/universal-scraper-api/api-reference)
- [JS Instructions](https://docs.zenrows.com/universal-scraper-api/features/js-instructions)
- [Error Codes](https://docs.zenrows.com/api-error-codes)

## License

MIT
