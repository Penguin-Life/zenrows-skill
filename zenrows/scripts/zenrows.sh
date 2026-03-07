#!/usr/bin/env bash
# zenrows.sh — Convenience wrapper for the ZenRows Universal Scraper API.
# Usage: zenrows.sh <url> [options]
# Run with --help for full options.

set -euo pipefail

API_BASE="https://api.zenrows.com/v1/"
MAX_RETRIES=2
RETRY_DELAY=3
TIMEOUT=120

if [[ -z "${ZENROWS_API_KEY:-}" ]]; then
  echo "Error: ZENROWS_API_KEY environment variable is not set." >&2
  exit 1
fi

# --- Helpers ---

# Pure bash URL encoding (no python3 dependency)
url_encode() {
  local string="$1" char encoded=""
  local i length=${#string}
  for (( i = 0; i < length; i++ )); do
    char="${string:i:1}"
    case "$char" in
      [a-zA-Z0-9.~_-]) encoded+="$char" ;;
      *) encoded+=$(printf '%%%02X' "'$char") ;;
    esac
  done
  echo "$encoded"
}

# Mask API key for verbose output
mask_key() {
  local key="$1"
  if [[ ${#key} -gt 8 ]]; then
    echo "${key:0:4}...${key: -4}"
  else
    echo "****"
  fi
}

show_help() {
  cat <<'EOF'
zenrows.sh — ZenRows Universal Scraper API wrapper

USAGE:
  zenrows.sh <url> [options]

OPTIONS:
  --auto              Adaptive Stealth Mode (mode=auto)
  --js                Enable JS rendering (js_render=true)
  --premium           Use premium/residential proxies
  --country <CC>      Proxy country (2-letter code, implies --premium)
  --markdown          Return markdown output
  --text              Return plaintext output
  --pdf               Return PDF output
  --autoparse         Auto-extract structured data
  --css '<json>'      CSS extractor (JSON object)
  --wait <ms>         Wait fixed milliseconds (requires --js)
  --wait-for <sel>    Wait for CSS selector (requires --js)
  --block <types>     Block resources: stylesheet,image,media,font,script
  --session <id>      Session ID for IP persistence (requires --premium)
  --captcha           Resolve CAPTCHAs (requires --js --premium)
  --screenshot        Return base64 screenshot (requires --js)
  --json              Wrap response in JSON with headers/status
  --device <d>        desktop or mobile (requires --js)
  --window <WxH>      Window size e.g. 1920x1080 (requires --js)
  --js-instructions '<json_array>'  JS instructions (requires --js)
  --post <body>       Send POST request with body
  --header <H:V>      Add custom header (repeatable)
  --original-status   Return target site's HTTP status code
  --retries <n>       Max retries on failure (default: 2)
  --timeout <s>       Request timeout in seconds (default: 120)
  -o <file>           Write output to file instead of stdout
  -v                  Verbose (show request info to stderr, API key masked)

CREDIT COSTS:
  Basic: 1 | JS: 5 | Premium: 5 | JS+Premium: 10 | CAPTCHA: +25 | Auto: variable

EXAMPLES:
  zenrows.sh "https://example.com" --markdown
  zenrows.sh "https://protected-site.com" --auto
  zenrows.sh "https://spa-app.com" --js --wait-for ".content"
  zenrows.sh "https://news.site.com" --css '{"title":"h1","body":".article-body"}'
EOF
}

# --- Argument parsing ---

if [[ $# -lt 1 ]]; then
  echo "Usage: zenrows.sh <url> [options]" >&2
  echo "Run with --help for full options." >&2
  exit 1
fi

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
  show_help
  exit 0
fi

TARGET_URL="$1"
shift

# Defaults
MODE=""
JS_RENDER=""
PREMIUM=""
PROXY_COUNTRY=""
RESPONSE_TYPE=""
AUTOPARSE=""
CSS_EXTRACTOR=""
WAIT=""
WAIT_FOR=""
BLOCK_RESOURCES=""
SESSION_ID=""
CAPTCHA=""
SCREENSHOT=""
JSON_RESPONSE=""
DEVICE=""
WINDOW_W=""
WINDOW_H=""
JS_INSTRUCTIONS=""
POST_BODY=""
ORIGINAL_STATUS=""
OUTPUT_FILE=""
VERBOSE=""
CUSTOM_HEADERS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto)        MODE="auto"; shift ;;
    --js)          JS_RENDER="true"; shift ;;
    --premium)     PREMIUM="true"; shift ;;
    --country)     PROXY_COUNTRY="$2"; PREMIUM="true"; shift 2 ;;
    --markdown)    RESPONSE_TYPE="markdown"; shift ;;
    --text)        RESPONSE_TYPE="plaintext"; shift ;;
    --pdf)         RESPONSE_TYPE="pdf"; shift ;;
    --autoparse)   AUTOPARSE="true"; shift ;;
    --css)         CSS_EXTRACTOR="$2"; shift 2 ;;
    --wait)        WAIT="$2"; shift 2 ;;
    --wait-for)    WAIT_FOR="$2"; shift 2 ;;
    --block)       BLOCK_RESOURCES="$2"; shift 2 ;;
    --session)     SESSION_ID="$2"; PREMIUM="true"; shift 2 ;;
    --captcha)     CAPTCHA="true"; JS_RENDER="true"; PREMIUM="true"; shift ;;
    --screenshot)  SCREENSHOT="true"; JS_RENDER="true"; shift ;;
    --json)        JSON_RESPONSE="true"; shift ;;
    --device)      DEVICE="$2"; JS_RENDER="true"; shift 2 ;;
    --window)      IFS='x' read -r WINDOW_W WINDOW_H <<< "$2"; JS_RENDER="true"; shift 2 ;;
    --js-instructions) JS_INSTRUCTIONS="$2"; JS_RENDER="true"; shift 2 ;;
    --post)        POST_BODY="$2"; shift 2 ;;
    --header)      CUSTOM_HEADERS+=("$2"); shift 2 ;;
    --original-status) ORIGINAL_STATUS="true"; shift ;;
    --retries)     MAX_RETRIES="$2"; shift 2 ;;
    --timeout)     TIMEOUT="$2"; shift 2 ;;
    -o)            OUTPUT_FILE="$2"; shift 2 ;;
    -v)            VERBOSE="true"; shift ;;
    --help|-h)     show_help; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- Build query string ---

build_qs() {
  local qs="apikey=${ZENROWS_API_KEY}"
  qs+="&url=$(url_encode "$TARGET_URL")"

  [[ -n "$MODE" ]]             && qs+="&mode=$MODE"
  [[ -n "$JS_RENDER" ]]        && qs+="&js_render=$JS_RENDER"
  [[ -n "$PREMIUM" ]]          && qs+="&premium_proxy=$PREMIUM"
  [[ -n "$PROXY_COUNTRY" ]]    && qs+="&proxy_country=$PROXY_COUNTRY"
  [[ -n "$RESPONSE_TYPE" ]]    && qs+="&response_type=$RESPONSE_TYPE"
  [[ -n "$AUTOPARSE" ]]        && qs+="&autoparse=$AUTOPARSE"
  [[ -n "$CSS_EXTRACTOR" ]]    && qs+="&css_extractor=$(url_encode "$CSS_EXTRACTOR")"
  [[ -n "$WAIT" ]]             && qs+="&wait=$WAIT"
  [[ -n "$WAIT_FOR" ]]         && qs+="&wait_for=$(url_encode "$WAIT_FOR")"
  [[ -n "$BLOCK_RESOURCES" ]]  && qs+="&block_resources=$BLOCK_RESOURCES"
  [[ -n "$SESSION_ID" ]]       && qs+="&session_id=$SESSION_ID"
  [[ -n "$CAPTCHA" ]]          && qs+="&resolve_captcha=$CAPTCHA"
  [[ -n "$SCREENSHOT" ]]       && qs+="&return_screenshot=$SCREENSHOT"
  [[ -n "$JSON_RESPONSE" ]]    && qs+="&json_response=$JSON_RESPONSE"
  [[ -n "$DEVICE" ]]           && qs+="&device=$DEVICE"
  [[ -n "$WINDOW_W" ]]         && qs+="&window_width=$WINDOW_W"
  [[ -n "$WINDOW_H" ]]         && qs+="&window_height=$WINDOW_H"
  [[ -n "$ORIGINAL_STATUS" ]]  && qs+="&original_status=$ORIGINAL_STATUS"
  [[ -n "$JS_INSTRUCTIONS" ]]  && qs+="&js_instructions=$(url_encode "$JS_INSTRUCTIONS")"

  if [[ ${#CUSTOM_HEADERS[@]} -gt 0 ]]; then
    qs+="&custom_headers=true"
  fi

  echo "$qs"
}

QS="$(build_qs)"
FULL_URL="${API_BASE}?${QS}"

# --- Build curl command ---

CURL_ARGS=(curl -s -S --max-time "$TIMEOUT")

# Add custom headers
for h in "${CUSTOM_HEADERS[@]+"${CUSTOM_HEADERS[@]}"}"; do
  CURL_ARGS+=(-H "$h")
done

# POST or GET
if [[ -n "$POST_BODY" ]]; then
  CURL_ARGS+=(-X POST -d "$POST_BODY")
fi

# Output to file
if [[ -n "$OUTPUT_FILE" ]]; then
  CURL_ARGS+=(-o "$OUTPUT_FILE")
fi

CURL_ARGS+=(-w '\n%{http_code}')
CURL_ARGS+=("$FULL_URL")

# --- Verbose logging (mask API key) ---

if [[ -n "$VERBOSE" ]]; then
  masked_url="${FULL_URL//$ZENROWS_API_KEY/$(mask_key "$ZENROWS_API_KEY")}"
  echo "Request: GET $masked_url" >&2
  echo "Timeout: ${TIMEOUT}s | Max retries: ${MAX_RETRIES}" >&2
fi

# --- Execute with retry ---

attempt=0
while true; do
  attempt=$((attempt + 1))
  response=$("${CURL_ARGS[@]}" 2>&1) && curl_exit=0 || curl_exit=$?

  if [[ $curl_exit -ne 0 ]]; then
    if [[ $attempt -le $MAX_RETRIES ]]; then
      echo "Retry $attempt/$MAX_RETRIES (curl exit $curl_exit)..." >&2
      sleep "$RETRY_DELAY"
      continue
    fi
    echo "Error: Request failed after $attempt attempts (curl exit $curl_exit)" >&2
    echo "$response" >&2
    exit 1
  fi

  # Extract HTTP status code (last line)
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  # Retry on 429 (rate limit) or 5xx
  if [[ "$http_code" =~ ^(429|5[0-9][0-9])$ ]] && [[ $attempt -le $MAX_RETRIES ]]; then
    echo "Retry $attempt/$MAX_RETRIES (HTTP $http_code)..." >&2
    sleep "$RETRY_DELAY"
    continue
  fi

  if [[ "$http_code" -ge 400 ]]; then
    echo "Error: HTTP $http_code" >&2
    echo "$body" >&2
    exit 1
  fi

  # Success — output body (unless -o was used, curl already wrote to file)
  if [[ -z "$OUTPUT_FILE" ]]; then
    echo "$body"
  else
    [[ -n "$VERBOSE" ]] && echo "Written to: $OUTPUT_FILE" >&2
  fi
  break
done
