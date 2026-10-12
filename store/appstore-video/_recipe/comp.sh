#!/bin/bash
set -e
S="$1"; N="$2"
read PW PH PX PY < <(python3 -c "import json;d=json.load(open('$S/$N.json'));print(d['PW'],d['PH'],d['px'],d['py'])")
ffmpeg -v error -y -loop 1 -i "$S/$N-bg.png" -i "$S/center.mp4" -loop 1 -i "$S/$N-mask.png" -filter_complex \
 "[1:v]scale=$PW:$PH:flags=lanczos,format=rgba[v];[2:v]format=gray[m];[v][m]alphamerge[vm];[0:v][vm]overlay=$PX:$PY:shortest=1,fps=30,format=yuv420p[o]" \
 -map "[o]" -t 27 -c:v libx264 -profile:v high -crf 20 -preset medium -maxrate 40M -bufsize 80M -movflags +faststart "$S/$N.mp4"
