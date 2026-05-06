#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-4567}
BASE_URL="http://localhost:$PORT"
APP_PID=""

# Prefer Homebrew Ruby 3.3 over the macOS system Ruby 2.6
for HOMEBREW_RUBY in \
    "/opt/homebrew/opt/ruby@3.3/bin" \
    "/opt/homebrew/Cellar/ruby@3.3/3.3.11/bin" \
    "/opt/homebrew/opt/ruby/bin"; do
  if [[ -x "$HOMEBREW_RUBY/ruby" && "$PATH" != *"$HOMEBREW_RUBY"* ]]; then
    export PATH="$HOMEBREW_RUBY:$PATH"
    break
  fi
done

# Point Selenium Manager to a user-writable cache (~/.cache is root-owned on macOS)
SE_CACHE="$HOME/Library/Caches/selenium"
mkdir -p "$SE_CACHE"
export SE_CACHE_PATH="$SE_CACHE"

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ── Cleanup on exit ────────────────────────────────────────────────────────────
cleanup() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    info "Stopping Sinatra (PID $APP_PID)..."
    kill "$APP_PID" && wait "$APP_PID" 2>/dev/null || true
    success "App stopped."
  fi
}
trap cleanup EXIT INT TERM

# ── Usage ──────────────────────────────────────────────────────────────────────
usage() {
  echo -e "${BOLD}Usage:${RESET} $0 [command]"
  echo ""
  echo "  ${BOLD}app${RESET}      Start the Sinatra server (foreground)"
  echo "  ${BOLD}test${RESET}     Start app + run full Cucumber suite, then stop app"
  echo "  ${BOLD}api${RESET}      Start app + run API tests only, then stop app"
  echo "  ${BOLD}ui${RESET}       Start app + run UI tests only, then stop app"
  echo "  ${BOLD}report${RESET}   Same as 'test' but opens HTML report when done"
  echo ""
  echo "  ${BOLD}ENV vars:${RESET}"
  echo "    PORT=4567      App port (default: 4567)"
  echo "    HEADLESS=true  Run Chrome headless (default: false)"
  echo "    CI=true        Headless + no colour (set automatically in CI)"
}

# ── Start the app in the background ───────────────────────────────────────────
start_app() {
  info "Starting Sinatra on $BASE_URL ..."

  # Kill any existing process on the port
  if lsof -ti tcp:"$PORT" &>/dev/null; then
    warn "Port $PORT already in use — killing existing process..."
    lsof -ti tcp:"$PORT" | xargs kill -9 2>/dev/null || true
    sleep 1
  fi

  bundle exec ruby app/app.rb &
  APP_PID=$!

  # Wait until the app responds (max 15 s)
  local attempts=0
  until curl -sf "$BASE_URL" >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [[ $attempts -ge 30 ]]; then
      error "App did not start within 15 seconds."
      exit 1
    fi
    sleep 0.5
  done

  success "App is up (PID $APP_PID)"
}

# ── Run Cucumber ───────────────────────────────────────────────────────────────
run_cucumber() {
  local feature="${1:-features}"
  local report_api="reports/cucumber_report.html"
  local report_ui="reports/cucumber_ui_report.html"

  mkdir -p reports

  echo ""
  echo -e "${BOLD}════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  Running: $feature${RESET}"
  echo -e "${BOLD}════════════════════════════════════════${RESET}"
  echo ""

  local exit_code=0

  if [[ "$feature" == "features/invoice_api.feature" ]]; then
    CUCUMBER_PUBLISH_QUIET=true bundle exec cucumber "$feature" \
      --format html --out "$report_api" \
      --format pretty \
      || exit_code=$?
    [[ $exit_code -eq 0 ]] && success "API tests passed — $report_api" \
                            || error   "API tests FAILED — see $report_api"

  elif [[ "$feature" == "features/invoice_ui.feature" ]]; then
    CUCUMBER_PUBLISH_QUIET=true bundle exec cucumber "$feature" \
      --format html --out "$report_ui" \
      --format pretty \
      || exit_code=$?
    [[ $exit_code -eq 0 ]] && success "UI tests passed — $report_ui" \
                            || error   "UI tests FAILED — see $report_ui"

  else
    # Full suite: run API then UI so failures in one don't skip the other
    CUCUMBER_PUBLISH_QUIET=true bundle exec cucumber features/invoice_api.feature \
      --format html --out "$report_api" \
      --format pretty \
      || exit_code=$?
    [[ $exit_code -eq 0 ]] && success "API tests passed" || error "API tests FAILED"

    local ui_exit=0
    CUCUMBER_PUBLISH_QUIET=true bundle exec cucumber features/invoice_ui.feature \
      --format html --out "$report_ui" \
      --format pretty \
      || ui_exit=$?
    [[ $ui_exit -eq 0 ]] && success "UI tests passed" || error "UI tests FAILED"

    [[ $ui_exit -ne 0 ]] && exit_code=$ui_exit
  fi

  return $exit_code
}

# ── Open report in browser (macOS / Linux) ────────────────────────────────────
open_report() {
  if command -v open &>/dev/null; then
    open reports/cucumber_report.html 2>/dev/null || true
    open reports/cucumber_ui_report.html 2>/dev/null || true
  elif command -v xdg-open &>/dev/null; then
    xdg-open reports/cucumber_report.html 2>/dev/null || true
    xdg-open reports/cucumber_ui_report.html 2>/dev/null || true
  else
    warn "Could not auto-open reports — open the files in reports/ manually."
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────────
COMMAND="${1:-help}"

case "$COMMAND" in
  app)
    start_app
    # Hand control back — keep app running in foreground
    APP_PID=""          # don't kill on exit
    wait
    ;;

  test)
    start_app
    run_cucumber "features"
    ;;

  api)
    start_app
    run_cucumber "features/invoice_api.feature"
    ;;

  ui)
    start_app
    run_cucumber "features/invoice_ui.feature"
    ;;

  report)
    start_app
    run_cucumber "features" || true
    open_report
    ;;

  help|--help|-h|*)
    usage
    ;;
esac
