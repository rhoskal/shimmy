# FFmpeg Command Patterns

These are templates, not commands to run unchanged. Replace placeholders only after inspecting the input and confirming the output plan. Follow the authorization policy in `../../media-processing/SKILL.md`: explicit, unambiguous single-file change requests authorize execution; advice requests do not. Ask for confirmation when necessary, and never overwrite an existing file without specific approval.

## 1. Preserve all streams without re-encoding

```bash
ffmpeg -hide_banner -i "INPUT.mkv" \
  -map 0 \
  -c copy \
  -map_chapters 0 \
  "OUTPUT.mkv"
```

Use when the goal is to remux all mapped streams from the first input. Check whether attachments, data streams, and every codec are supported in the target container. If the goal is to keep only specific stream types, do not use this template.

## 2. Keep first video, first audio, and all subtitles if present

```bash
ffmpeg -hide_banner -i "INPUT.mkv" \
  -map 0:v:0 \
  -map 0:a:0 \
  -map "0:s?" \
  -c copy \
  -map_chapters 0 \
  "OUTPUT.mkv"
```

This intentionally omits other audio tracks, additional video tracks, attachments and data streams. The optional subtitle map allows zero subtitle streams without failing due to that map alone.

## 3. Keep first video, first audio, and two selected input subtitle streams

```bash
ffmpeg -hide_banner -i "INPUT.mkv" \
  -map 0:v:0 \
  -map 0:a:0 \
  -map 0:s:0 \
  -map 0:s:1 \
  -c copy \
  -map_chapters 0 \
  "OUTPUT.mkv"
```

Use only after confirming both subtitle streams exist. This maps the first and second subtitle streams from input 0, in that order. Output subtitle indexes will be `0` and `1` in this template.

## 4. Set audio title and language while copying streams

```bash
ffmpeg -hide_banner -i "INPUT.mkv" \
  -map 0:v:0 \
  -map 0:a:0 \
  -map "0:s?" \
  -c copy \
  -map_chapters 0 \
  -metadata:s:a:0 "title=EAC3 Stereo @ 224 kbps" \
  -metadata:s:a:0 "language=eng" \
  "OUTPUT.mkv"
```

The title and language apply to output audio stream 0. Only use a title whose codec/layout/bitrate description has been verified or is explicitly intended as a label.

## 5. Convert selected audio to E-AC-3, preserve video/subtitles

```bash
ffmpeg -hide_banner -i "INPUT.mkv" \
  -map 0:v:0 \
  -map 0:a:0 \
  -map "0:s?" \
  -c:v copy \
  -c:a eac3 -b:a 1536k -ac 6 \
  -c:s copy \
  -map_chapters 0 \
  -metadata:s:a:0 "title=EAC3 5.1 @ 1536 kbps" \
  -metadata:s:a:0 "language=eng" \
  "OUTPUT.mkv"
```

This re-encodes the selected audio stream; it is not a lossless stream copy. Verify that the output actually has the expected six-channel layout and that the chosen bitrate is appropriate. The example's language is only a placeholder convention; use the real audio language.

## 6. Add an external SRT subtitle

```bash
ffmpeg -hide_banner -i "INPUT.mkv" -i "SUBTITLE.srt" \
  -map 0:v:0 \
  -map 0:a \
  -map 1:0 \
  -c copy \
  -c:s srt \
  -map_chapters 0 \
  -metadata:s:s:0 language=eng \
  -metadata:s:s:0 title="English" \
  "OUTPUT.mkv"
```

The SRT is input 1, stream 0. `-metadata:s:s:0` refers to the first subtitle stream in the output. This template intentionally maps the first video stream, all audio streams, and one external subtitle. Confirm that all mapped audio streams are wanted. If adding the subtitle to a previously trimmed file, ensure the SRT timing matches that file.

## 7. Fast stream-copy seek/cut

```bash
ffmpeg -hide_banner -ss 15 -i "INPUT.mkv" \
  -map 0 \
  -c copy \
  "OUTPUT.mkv"
```

This is a stream-copy cut with seeking. It is not guaranteed to start on an exact frame or preserve every stream's timing as desired. Confirm whether `-ss` belongs before or after `-i` for the requested behavior and validate the actual output. Do not use for precise cuts without discussing re-encoding and timing requirements.

## 8. Shift or trim external SRT timing

A simple input-side seek can be written as:

```bash
ffmpeg -hide_banner -ss 14 -i "INPUT.srt" "OUTPUT.srt"
```

Do not assume this command implements the user's intended subtitle edit correctly for every SRT or FFmpeg build. Determine whether the requirement is to offset all cue times, remove cues before a boundary, or align subtitles to a trimmed video. Prefer a subtitle-aware operation with explicit timing semantics, then inspect the first and last cues.

## 9. Set subtitle title/language and hearing-impaired disposition

```bash
ffmpeg -hide_banner -i "INPUT.mkv" \
  -map 0 \
  -c copy \
  -map_chapters 0 \
  -metadata:s:s:1 title="English SDH" \
  -metadata:s:s:1 language=eng \
  -disposition:s:1 hearing_impaired \
  "OUTPUT.mkv"
```

This example assumes the second **output** subtitle is the intended SDH track. Verify output ordering. A disposition assignment may set the specified disposition rather than merely add it to existing flags; use FFmpeg's `+flag` or `-flag` syntax when the goal is to preserve and modify existing flags. Verify all resulting dispositions.

## Validation after any command

Inspect the output, not just the exit code:

```bash
ffprobe -v error \
  -show_entries format=filename,duration,size:stream=index,codec_type,codec_name,profile,channels,channel_layout,bit_rate:stream_tags=language,title \
  -show_entries stream_disposition \
  -of json "OUTPUT.mkv"
```

Compare the output's ordered streams, codecs, languages, titles, dispositions, chapters, duration and size with the plan. If any expected property is missing or unclear, report that rather than claiming success.
