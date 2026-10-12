---
name: mkv-remux-validation
description: Use mkvmerge for lossless MKV track selection/removal and deliberate Matroska remuxing, and validate container, track, chapter, metadata, and output properties after media operations.
---

# MKV Remux & Validation

Use `mkvmerge` when a Matroska remux is needed. Do not add a remux merely because a previous workflow included one.

## Decide whether remuxing is necessary

Clarify the goal first: Matroska compatibility, track selection/order, container-level metadata handling, or another specific reason. Prefer `mkvmerge` for selecting/removing existing MKV tracks without conversion, especially when a remux or statistics regeneration is also requested. If the prior FFmpeg output already satisfies the request, explain why an additional remux may be unnecessary.

If only statistics need refreshing and a remux was not explicitly requested, use `mkvpropedit --add-track-statistics-tags` as described in `../mkv-metadata/SKILL.md`. `mkvmerge` generates track statistics by default unless disabled with `--disable-track-statistics-tags`.

## Inspect before remuxing

```bash
mkvmerge -J "INPUT.mkv"
```

Review track IDs/types, codecs, languages, names, default/forced/hearing-impaired flags, chapters and attachments where relevant.

## Basic remux template

```bash
mkvmerge --output "OUTPUT.mkv" "INPUT.mkv"
```

`--quiet` can suppress normal output but should not be used when it would make diagnosis harder. For a first run or troubleshooting, prefer visible output. Always check the exit status and inspect the resulting file.

## Lossless track selection

After inspection, use MKVToolNix track IDs (not FFmpeg indexes or `mkvpropedit` selectors):

```bash
mkvmerge --output "OUTPUT.mkv" \
  --audio-tracks 1 \
  --subtitle-tracks 3,4 \
  --track-name "1:EAC3 5.1 @ 1024 kbps" \
  "INPUT.mkv"
```

These IDs and the title are examples, not defaults. Verify them against the actual source. Selection options retain only the listed tracks of that type; other track types, chapters, attachments and metadata remain subject to `mkvmerge` defaults unless explicitly controlled. Streams are not re-encoded. Verify retained content and flags afterward.

Follow `../media-processing/SKILL.md` for authorization. An explicit single-file request authorizes the requested operation once the plan is unambiguous; ask if selection or consequences are unclear. Use a distinct output path and check for collisions before writing. Never overwrite an existing file without specific approval.

## Validation

Use `references/inspection-checklist.md`. At minimum:
- verify the output exists and is non-empty;
- inspect output tracks with `mkvmerge -J` and/or `ffprobe`;
- compare stream count/order, codec, language, names and flags against the plan;
- verify chapters and attachments if they matter;
- check duration and playback/synchronization where trimming or subtitles were involved.

Do not claim success based only on the command's exit status. Report differences and limitations explicitly.
