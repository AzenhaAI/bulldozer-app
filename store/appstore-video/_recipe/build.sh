#!/bin/bash
set -e
V=/private/tmp/claude-501/-Users-kirillshpara/025d8691-cfe3-48e0-a982-db40cbef8a62/scratchpad/vid; cd $V
segs=(12.0:16.8 19.6:21.6 24.6:28.6 36.6:38.4 39.0:41.0 45.7:48.7 53.6:56.0 86.8:89.0 95.6:98.4 107.5:110.2)
f=""; c=""; n=0
for s in "${segs[@]}"; do a=${s%:*}; b=${s#*:}; f="$f[0:v]trim=start=$a:end=$b,setpts=PTS-STARTPTS[s$n];"; c="$c[s$n]"; n=$((n+1)); done
ffmpeg -v error -y -i rec30.mp4 -filter_complex "${f}${c}concat=n=$n:v=1:a=0,fps=30,format=yuv420p[v]" -map "[v]" -c:v libx264 -crf 14 -preset slow center.mp4
ffprobe -v error -show_entries format=duration -of csv=p=0 center.mp4
bash comp.sh $V header && bash comp.sh $V search
ffmpeg -v error -y -ss 9 -i header.mp4 -frames:v 1 header-frame.png; ffmpeg -v error -y -ss 9 -i search.mp4 -frames:v 1 search-frame.png
ffmpeg -v error -y -i center.mp4 -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -filter_complex "[0:v]scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2:color=0x0b0d0f,setsar=1,fps=30,format=yuv420p[v]" -map "[v]" -map 1:a -t 27 -c:v libx264 -profile:v high -level 4.0 -crf 18 -c:a aac -b:a 128k -ar 44100 -ac 2 -movflags +faststart preview-886x1920.mp4
for x in header.mp4 search.mp4 preview-886x1920.mp4; do ffprobe -v error -show_entries stream=codec_name,width,height,channels -show_entries format=duration,size -of compact $x; done
