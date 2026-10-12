---
name: mkv-stream-operations
description: Plan FFmpeg operations for MKV stream mapping, stream copying, audio conversion, subtitle selection or insertion, metadata on output streams, and timestamp trimming. Use when changing which streams are included or how streams are encoded.
---

# MKV Stream Operations

Use FFmpeg for stream mapping, stream copying, encoding, external subtitle insertion, and timestamp operations. For selecting/removing existing MKV tracks without conversion, prefer `mkvmerge` under `../mkv-remux-validation/SKILL.md`. Follow `../media-processing/SKILL.md` for authorization.

## Workflow

1. Identify the exact source and desired output path. Do not overwrite the source by default.
2. Inspect the source before selecting streams. Prefer:
   - `ffprobe -v error -show_entries format=duration:stream=index,codec_type,codec_name,channels,channel_layout,bit_rate:stream_tags=language,title -show_entries stream_disposition -of json "INPUT.mkv"`
   - `ffmpeg -hide_banner -i "INPUT.mkv"` (inspection only; FFmpeg may exit nonzero because no output was supplied)
3. Translate the request into a stream plan: video, each audio stream, each subtitle stream, attachments/data if relevant, chapters, and metadata.
4. Choose explicit `-map` options. Use `-map 0` only when the intent is to map all streams from input 0; it can include stream types that the target container or codecs may not support.
5. Use `-c copy` for streams that should not be re-encoded. If converting audio, explicitly scope codec/bitrate/channel options to audio and map all desired non-audio streams too.
6. Set metadata and dispositions against the intended **output** streams, then check the resulting stream order.
7. Present the command or a brief execution notice and explain material trade-offs. An explicit request for an unambiguous single-file change authorizes execution; ask for confirmation if the target, selection, or consequences are unclear or exceed the request. Do not overwrite an existing file without specific approval.
8. Validate the output using the checklist in `references/ffmpeg-patterns.md` and `../mkv-remux-validation/references/inspection-checklist.md`.

## Stream-index semantics

- `-map 0:s:1` selects the second subtitle stream in input file 0. FFmpeg's type-relative input stream specifiers are zero-based.
- `-metadata:s:s:1 ...` addresses the second subtitle stream in the **output** stream order, not necessarily the same source stream as `0:s:1` if mapping or reordering changed the set/order.
- `-metadata:s:a:0 ...` addresses the first audio stream in the output.
- When stream selection changes output order, calculate output indexes from the exact ordered `-map` list. Never copy index assumptions from a prior file.
- Optional mapping `-map "0:s?"` means map subtitle streams if present. It does not mean select only one subtitle.
- `-map 0:v:0` means first video stream from input 0; `-map 0:a:0` means first audio stream; `-map 0:s` maps all subtitle streams.

## Audio conversion

- Use `-c:a eac3 -b:a 1536k -ac 6` only when E-AC-3, the requested bitrate, and six-channel output are intended and supported by the source/workflow.
- When only audio should be converted, explicitly copy video and subtitles (for example, `-c:v copy -c:a eac3 ... -c:s copy`) and map the desired streams.
- A title such as `EAC3 5.1 @ 1536 kbps` is descriptive only. Inspect the actual output codec, channel layout and bitrate before using that title.
- Do not promise bit-exact audio quality after transcoding.

## Subtitle handling

Use `references/subtitle-workflows.md` for adding an external SRT, selecting embedded subtitle streams, naming English/SDH tracks, and setting hearing-impaired dispositions.

## Trimming

- `-ss` with `-c copy` is a fast stream-copy cut, not a guarantee of frame-accurate cutting. Seek behavior depends on input format, timestamps, and keyframes.
- For external SRT files, shifting the start by a fixed amount is not always equivalent to correctly trimming every cue. Confirm whether the desired operation is a time shift, removing cues before a point, or making a subtitle file correspond to a cut video.
- State the intended timing behavior and validate duration, first/last timestamps, and subtitle synchronization.
