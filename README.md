# Timelapse

A simple macOS utility to capture screenshots at regular intervals for creating timelapse videos.

## Usage

```bash
./timelapse.sh [name] [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-i, --interval N` | Seconds between captures | 30 |
| `-f, --format FMT` | Image format: `jpg` or `png` | jpg |
| `-o, --output DIR` | Output directory | . |
| `-h, --help` | Show help | |

### Examples

```bash
./timelapse.sh redesign                   # Basic usage, 30s interval
./timelapse.sh coding -i 20               # 20s interval for more detail
./timelapse.sh session -f png             # Lossless PNG format
./timelapse.sh demo -o ~/Desktop          # Save to specific directory
```

Press `Ctrl+C` to stop recording.

## Output

Screenshots are saved to `./<name>/<name>-000001.jpg` (or `.png`). The script automatically resumes numbering if you restart it with the same sequence name.

## Creating Video

After capturing, use ffmpeg to create a video:

```bash
ffmpeg -framerate 24 -pattern_type glob -i './redesign/redesign-*.jpg' \
  -c:v libx264 -crf 20 -pix_fmt yuv420p redesign.mp4
```

## Interval Guide

For a 16-hour recording session at 30fps output:

| Interval | Frames | Video Length | Size |
|----------|--------|--------------|------|
| 20s | ~2,880 | 96s | 3-6 GB |
| 30s | ~1,920 | 64s | 2-4 GB |
| 60s | ~960 | 32s | 1-2 GB |

## Requirements

- macOS
- Screen recording permission for your terminal app (System Settings → Privacy & Security → Screen Recording)
