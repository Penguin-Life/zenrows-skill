---
name: zenrows
description: Fetch web page content via ZenRows Universal Scraper API — a proxy/scraping service that handles anti-bot bypasses, JS rendering, CAPTCHA solving, and proxy rotation. Use when: (1) web_fetch fails or returns blocked/empty content, (2) a target site has anti-bot protection (Cloudflare, DataDome, etc.), (3) you need JS-rendered content from SPAs, (4) you need to extract structured data via CSS selectors or autoparse, (5) you need content as markdown/plaintext/PDF/screenshot. Requires a ZENROWS_API_KEY environment variable.
---

# ZenRows

Fetch web content through the [ZenRows Universal Scraper API](https://www.zenrows.com/).
ZenRows handles proxy rotation, headless browsers, anti-bot bypasses, and CAPTCHAs automatically.

## Quick Start

Use the bundled helper script for common fetches:

```bash
# Basic fetch (returns HTML)
scripts/zenrows.sh "https://example.com"

# Markdown output (ideal for LLM consumption)
scripts/zenrows.sh "https://example.com" --markdown

# Plaintext output
scripts/zenrows.sh "https://example.com" --text

# Auto mode (let ZenRows pick optimal config)
scripts/zenrows.sh "https://example.com" --auto
```

## Direct API Usage (curl)

The API endpoint is `https://api.zenrows.com/v1/`. All parameters go as query strings.

```bash
# Minimal request
curl -s "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com"

# With JS rendering (5 credits)
curl -s "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com&js_render=true"

# Auto mode — ZenRows picks optimal anti-bot config (variable credits)
curl -s "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com&mode=auto"

# Markdown output
curl -s "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com&response_type=markdown"

# Plaintext output
curl -s "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://example.com&response_type=plaintext"
```

## API Parameters Reference

### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apikey` | string | required | API key |
| `url` | string | required | Target URL (must be URL-encoded) |
| `mode` | string | — | `auto` = Adaptive Stealth Mode (auto-selects js_render, premium_proxy, etc.) |

### Output Control

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `response_type` | string | html | `markdown`, `plaintext`, or `pdf` |
| `json_response` | bool | false | Wrap response in JSON with headers/status |
| `original_status` | bool | false | Return the target site's HTTP status code |
| `return_screenshot` | bool | false | Return a base64-encoded screenshot (requires `js_render`) |

### Anti-Bot & Rendering

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `js_render` | bool | false | Render JS with headless browser (5 credits) |
| `premium_proxy` | bool | false | Use residential proxies (10 credits) |
| `proxy_country` | string | — | 2-letter country code (requires `premium_proxy`) |
| `resolve_captcha` | bool | false | Auto-solve CAPTCHAs (requires `js_render` + `premium_proxy`) |

### JS Rendering Options (require `js_render=true`)

| Parameter | Type | Description |
|-----------|------|-------------|
| `wait` | int | Wait fixed ms before returning |
| `wait_for` | string | Wait for CSS selector to appear in DOM |
| `block_resources` | string | Block resource types: `stylesheet`, `image`, `media`, `font`, `script` (comma-separated) |
| `window_width` | int | Browser viewport width (default 1920) |
| `window_height` | int | Browser viewport height (default 1080) |
| `device` | string | `desktop` or `mobile` (sets user-agent accordingly) |

### Data Extraction

| Parameter | Type | Description |
|-----------|------|-------------|
| `autoparse` | bool | Auto-extract structured data (product pages, articles, etc.) |
| `css_extractor` | string | JSON object mapping field names to CSS selectors. Use `@attr` suffix for attributes (e.g. `{"links":"a @href","titles":"h2"}`) |

### Session & Headers

| Parameter | Type | Description |
|-----------|------|-------------|
| `session_id` | int | Reuse the same IP across requests (0–99999999, requires `premium_proxy`) |
| `custom_headers` | bool | When true, pass custom headers via request headers |

### JS Instructions (require `js_render=true`)

Pass as `js_instructions` parameter (URL-encoded JSON array):

```json
[
  {"action": "click", "selector": "#load-more"},
  {"action": "wait", "timeout": 2000},
  {"action": "fill", "selector": "#search", "value": "query"},
  {"action": "evaluate", "code": "document.title"},
  {"action": "scroll_y", "value": 500},
  {"action": "wait_for_selector", "selector": ".results"}
]
```

Available actions: `click`, `fill`, `check`, `uncheck`, `select_option`, `wait`, `wait_for_selector`, `scroll_x`, `scroll_y`, `evaluate`, `solve_captcha`.

### POST Requests

Send POST data by making a POST request to the API with body content:

```bash
curl -X POST "https://api.zenrows.com/v1/?apikey=$ZENROWS_API_KEY&url=https://httpbin.org/post" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

## Credit Costs

| Configuration | Credits per Request |
|--------------|-------------------|
| Basic (no extras) | 1 |
| `js_render=true` | 5 |
| `premium_proxy=true` | 5 |
| `js_render` + `premium_proxy` | 10 |
| `resolve_captcha=true` | 25 (added) |
| `mode=auto` | Variable (billed for what succeeds) |

## Decision Guide

```
Need web content?
├── Try web_fetch first (free, no credits)
├── web_fetch blocked/empty?
│   ├── Static site with basic protection
│   │   └── zenrows basic (1 credit)
│   ├── JS-heavy SPA or moderate anti-bot
│   │   └── zenrows --js (5 credits)
│   ├── Strong anti-bot (Cloudflare, DataDome)
│   │   └── zenrows --auto (variable credits, auto-optimized)
│   └── Need structured data extraction
│       └── zenrows --autoparse or --css-extract (+ applicable rendering credits)
└── Need markdown/text for LLM context?
    └── zenrows --markdown or --text
```

## Common Patterns

### Fetch page as markdown for LLM context
```bash
scripts/zenrows.sh "https://docs.example.com/api" --markdown
```

### Scrape with anti-bot bypass
```bash
scripts/zenrows.sh "https://protected-site.com" --auto
```

### Extract specific data with CSS selectors
```bash
scripts/zenrows.sh "https://news.site.com/article" \
  --css '{"title":"h1","body":".article-body","author":".byline"}'
```

### JS-rendered page with wait
```bash
scripts/zenrows.sh "https://spa-app.com/dashboard" --js --wait-for ".data-loaded"
```

### Get page from specific country
```bash
scripts/zenrows.sh "https://geo-restricted.com" --premium --country us
```
