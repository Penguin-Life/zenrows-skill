#!/usr/bin/env bash
# zenrows.sh — Convenience wrapper for the ZenRows Universal Scraper API.
# Usage: zenrows.sh <url> [options]
#
# Options:
#   --auto              Adaptive Stealth Mode (mode=auto)
#   --js                Enable JS rendering (js_render=true)
#   --premium           Use premium/residential proxies
#   --country <CC>      Proxy country (2-letter code, implies --premium)
#   --markdown          Return markdown output
#   --text              Return plaintext output
#   --pdf               Return PDF output
#   --autoparse         Auto-extract structured data
#   --css '<json>'      CSS extractor (JSON object)
#   --wait <ms>         Wait fixed milliseconds (requires --js)
#   --wait-for <sel>    Wait for CSS selector (requires --js)
#   --block <types>     Block resources: stylesheet,image,media,font,script
#   --session <id>      Session ID for IP persistence (requires --premium)
#   --captcha           Resolve CAPTCHAs (requires --js --premium)
#   --screenshot        Return base64 screenshot (requires --js)
#   --json              Wrap response in JSON with headers/status
#   --device <d>        desktop or mobile (requires --js)
#   --window <WxH>      Window size e.g. 1920x1080 (requires --js)
#   --js-instructions '<json_array>'  JS instructions (requires --js)
#   --post <body>       Send POST request with body
#   --header <H:V>      Add custom header (repeatable)
#   --original-status   Return target site's HTTP status code
#   -o <file>           Write output to file instead of stdout
#   -v                  Verbose (show curl info to stderr)

set -euo pipefail

API_BASE="https://api.zenrows.com/v1/"

if [[ -z "${ZENROWS_API_KEY:-}" ]]; then
  echo "Error: ZENROWS_API_KEY environment variable is not set." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: zenrows.sh <url> [options]" >&2
  echo "Run with --help for full options." >&2
  exit 1
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
declare -a CUSTOM_HEADERS=()

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
    -o)            OUTPUT_FILE="$2"; shift 2 ;;
    -v)            VERBOSE="true"; shift ;;
    --help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Build query string
build_qs() {
  local qs="apikey=${ZENROWS_API_KEY}"
  qs+="&url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$TARGET_URL', safe=''))")"

  [[ -n "$MODE" ]]             && qs+="&mode=$MODE"
  [[ -n "$JS_RENDER" ]]        && qs+="&js_render=$JS_RENDER"
  [[ -n "$PREMIUM" ]]          && qs+="&premium_proxy=$PREMIUM"
  [[ -n "$PROXY_COUNTRY" ]]    && qs+="&proxy_country=$PROXY_COUNTRY"
  [[ -n "$RESPONSE_TYPE" ]]    && qs+="&response_type=$RESPONSE_TYPE"
  [[ -n "$AUTOPARSE" ]]        && qs+="&autoparse=$AUTOPARSE"
  [[ -n "$CSS_EXTRACTOR" ]]    && qs+="&css_extractor=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CSS_EXTRACTOR', safe=''))")"
  [[ -n "$WAIT" ]]             && qs+="&wait=$WAIT"
  [[ -n "$WAIT_FOR" ]]         && qs+="&wait_for=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$WAIT_FOR', safe=''))")"
  [[ -n "$BLOCK_RESOURCES" ]]  && qs+="&block_resources=$BLOCK_RESOURCES"
  [[ -n "$SESSION_ID" ]]       && qs+="&session_id=$SESSION_ID"
  [[ -n "$CAPTCHA" ]]          && qs+="&resolve_captcha=$CAPTCHA"
  [[ -n "$SCREENSHOT" ]]       && qs+="&return_screenshot=$SCREENSHOT"
  [[ -n "$JSON_RESPONSE" ]]    && qs+="&json_response=$JSON_RESPONSE"
  [[ -n "$DEVICE" ]]           && qs+="&device=$DEVICE"
  [[ -n "$WINDOW_W" ]]         && qs+="&window_width=$WINDOW_W"
  [[ -n "$WINDOW_H" ]]         && qs+="&window_height=$WINDOW_H"
  [[ -n "$ORIGINAL_STATUS" ]]  && qs+="&original_status=$ORIGINAL_STATUS"
  [[ -n "$JS_INSTRUCTIONS" ]]  && qs+="&js_instructions=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$JS_INSTRUCTIONS', safe=''))")"

  # Enable custom_headers if any custom headers provided
  if [[ ${#CUSTOM_HEADERS[@]} -gt 0 ]]; then
    qs+="&custom_headers=true"
  fi

  echo "$qs"
}

QS="$(build_qs)"
FULL_URL="${API_BASE}?${QS}"

# Build curl command
declare -a CURL_CMD=(curl -s -S --max-time 120)

[[ -n "$VERBOSE" ]] && CURL_CMD+=(-v)

# Add custom headers
for h in "${CUSTOM_HEADERS[@]+"${CUSTOM_HEADERS[@]}"}"; do
  CURL_CMD+=(-H "$h")
done

# POST or GET
if [[ -n "$POST_BODY" ]]; then
  CURL_CMD+=(-X POST -d "$POST_BODY")
fi

# Output
if [[ -n "$OUTPUT_FILE" ]]; then
  CURL_CMD+=(-o "$OUTPUT_FILE")
fi

CURL_CMD+=("$FULL_URL")

# Execute
if [[ -n "$VERBOSE" ]]; then
  echo "Request: ${CURL_CMD[*]}" >&2
fi

"${CURL_CMD[@]}"
