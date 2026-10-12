# Subtitle Workflows

## Identify subtitles before selecting them

Use `ffprobe` or `mkvmerge -J` to list subtitle tracks, languages, names, codec/format and dispositions. Do not assume `s:1` means English or SDH based on a prior episode. Stream indexes are positional; metadata can be missing or wrong.

## Embedded subtitle selection

- `-map 0:s:0`: first subtitle stream in input 0.
- `-map 0:s:1`: second subtitle stream in input 0.
- `-map "0:s?"`: all subtitle streams from input 0, if present.
- `-metadata:s:s:0`: metadata for first subtitle in the output.
- `-metadata:s:s:1`: metadata for second subtitle in the output.

Input selection and output metadata are distinct. If you map only `0:s:1`, it commonly becomes output subtitle stream 0, so metadata must address `s:0`, not `s:1`.

## English and English SDH convention

A typical intended layout may be:
- English subtitle: `language=eng`, title `English`, hearing-impaired disposition off unless the track is actually SDH.
- English SDH subtitle: `language=eng`, title `English SDH`, hearing-impaired disposition on.

These are user conventions, not a way to infer a track's content. Confirm that the source subtitle is actually SDH. A track title does not create SDH captions or guarantee the disposition was written correctly.

## Add an external SRT

Before composing the command, establish:
1. Which video and audio tracks should remain.
2. Whether existing subtitles should be preserved, replaced, or omitted.
3. Whether the SRT timing matches the target video's timeline.
4. The desired output subtitle order and metadata.

Example:

```bash
ffmpeg -hide_banner -i "INPUT.mkv" -i "ENGLISH.srt" \
  -map 0:v:0 \
  -map 0:a \
  -map 1:0 \
  -c copy -c:s srt \
  -map_chapters 0 \
  -metadata:s:s:0 language=eng \
  -metadata:s:s:0 title="English" \
  "OUTPUT.mkv"
```

The first output subtitle in this mapping is the external SRT because no embedded subtitles are mapped. If embedded subtitles are also mapped, recalculate the output subtitle index.

## Trim video and synchronize subtitles

A video stream-copy cut and an SRT edit are separate operations. Ask what the user means by “trim subtitles”:
- shift all cue timestamps by a fixed offset;
- remove cues before a given time;
- clip cues to a time interval;
- synchronize an SRT with a video that was cut;
- extract a subtitle stream.

Do not assume `ffmpeg -ss TIME -i INPUT.srt OUTPUT.srt` satisfies all of these semantics. Inspect cue timestamps and check synchronization against the actual output video.
