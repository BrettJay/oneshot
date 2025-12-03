#!/usr/bin/env bash
set -euo pipefail

# Timelapse Screenshot Capture for macOS
# Usage: ./timelapse.sh [name] [--interval N] [--format jpg|png] [--quality N]

# Defaults
NAME="timelapse"
INTERVAL=30        # seconds between captures
FORMAT="jpg"       # jpg or png
OUTDIR="."

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [name] [options]

Captures screenshots at regular intervals for timelapse video creation.

Arguments:
  name              Sequence name (default: timelapse)
                    Creates folder ./name/ with files name-000001.jpg

Options:
  -i, --interval N  Seconds between captures (default: 30)
  -f, --format FMT  Image format: jpg or png (default: jpg)
  -o, --output DIR  Output directory (default: current directory)
  -h, --help        Show this help

Interval guidance (for 16-hour recording at 30fps output):
  20s → ~2,880 frames → 96s video  → ~3-6 GB
  30s → ~1,920 frames → 64s video  → ~2-4 GB (recommended)
  60s →   ~960 frames → 32s video  → ~1-2 GB

Examples:
  $(basename "$0") redesign                   # 30s interval, jpg
  $(basename "$0") coding -i 20               # 20s interval for more detail
  $(basename "$0") session -f png             # lossless PNG
  $(basename "$0") demo -o ~/Desktop          # save to Desktop

Press Ctrl+C to stop recording.
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;

        -o|--output)
            OUTDIR="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            print_usage
            exit 1
            ;;
        *)
            NAME="$1"
            shift
            ;;
    esac
done

# Validate format
if [[ "$FORMAT" != "jpg" && "$FORMAT" != "png" ]]; then
    echo "Error: format must be 'jpg' or 'png'" >&2
    exit 1
fi

# Create output directory and resolve to absolute path
SEQDIR="${OUTDIR}/${NAME}"
mkdir -p "$SEQDIR"
SEQDIR="$(cd "$SEQDIR" && pwd)"

# Find highest existing index to resume
find_last_index() {
    local pattern="${SEQDIR}/${NAME}-"*".${FORMAT}"
    local last
    last=$(ls $pattern 2>/dev/null | sed -E "s/.*${NAME}-([0-9]+)\.${FORMAT}/\1/" | sort -n | tail -1)
    echo "${last:-0}"
}

last_index=$(find_last_index)
seq=$((10#$last_index + 1))

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Timelapse Capture                                         ║"
echo "╠════════════════════════════════════════════════════════════╣"
printf "║  Sequence: %-48s║\n" "$NAME"
printf "║  Output:   %-48s║\n" "$SEQDIR/"
printf "║  Format:   %-48s║\n" "$FORMAT"
printf "║  Interval: %-48s║\n" "${INTERVAL}s"
if [[ 10#$last_index -gt 0 ]]; then
printf "║  Resuming: %-48s║\n" "from frame $seq (found $last_index existing)"
else
printf "║  Starting: %-48s║\n" "new sequence"
fi
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  Press Ctrl+C to stop                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Build screencapture args (note: -Q quality flag not available on all macOS versions)
sc_args=(-x "-t${FORMAT}")

# Test capture permissions first
test_file="${SEQDIR}/permission_test_$$.jpg"
capture_output=$(screencapture "${sc_args[@]}" "$test_file" 2>&1)
if [[ ! -s "$test_file" ]]; then
    rm -f "$test_file"
    echo ""
    if [[ "$capture_output" == *"cannot write file"* ]]; then
        echo "ERROR: Cannot write to output directory."
        echo ""
        echo "This can happen if the folder was created before screen recording"
        echo "permission was granted. Try removing and recreating the folder:"
        echo "  rm -rf \"$SEQDIR\" && mkdir \"$SEQDIR\""
    else
        echo "ERROR: Screen recording permission denied."
        echo ""
        echo "To fix:"
        echo "  1. Open System Settings → Privacy & Security → Screen Recording"
        echo "  2. Enable your terminal app (Terminal, iTerm2, Warp, etc.)"
        echo "  3. Restart your terminal and try again"
    fi
    echo ""
    exit 1
fi
rm -f "$test_file"

# Trap Ctrl+C for clean exit
cleanup() {
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "Stopped. Captured $((seq - last_index - 1)) frames this session."
    echo "Total frames in sequence: $((seq - 1))"
    echo "Location: $SEQDIR/"
    echo ""
    echo "To create video (24fps):"
    echo "  ffmpeg -framerate 24 -pattern_type glob -i '${SEQDIR}/${NAME}-*.${FORMAT}' \\"
    echo "    -c:v libx264 -crf 20 -pix_fmt yuv420p ${NAME}.mp4"
    exit 0
}
trap cleanup SIGINT SIGTERM

# Main capture loop
while true; do
    filename=$(printf "%s/%s-%06d.%s" "$SEQDIR" "$NAME" "$seq" "$FORMAT")
    
    if screencapture "${sc_args[@]}" "$filename" 2>/dev/null && [[ -s "$filename" ]]; then
        size=$(ls -lh "$filename" | awk '{print $5}')
        timestamp=$(date '+%H:%M:%S')
        printf "[%s] #%06d saved (%s)\n" "$timestamp" "$seq" "$size"
    else
        echo "[$(date '+%H:%M:%S')] Warning: capture failed for frame $seq"
    fi
    
    seq=$((seq + 1))
    sleep "$INTERVAL"
done
