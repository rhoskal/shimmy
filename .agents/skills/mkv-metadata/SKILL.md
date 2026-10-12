---
name: mkv-metadata
description: Edit Matroska track metadata with mkvpropedit, including track language, track name, default flags, and hearing-impaired flags. Use when modifying properties of existing MKV files without changing their stream content.
---

# MKV Metadata & Track Flags

Use `mkvpropedit` for supported in-place Matroska property edits and statistics refreshes. Unlike remuxing, it changes metadata in the existing file rather than creating a new output. Confirm the target path and follow the authorization policy in `../media-processing/SKILL.md`.

## Required workflow

1. Inspect the file using `mkvmerge -J "INPUT.mkv"` or an equivalent track listing.
2. Identify the intended track by type, language/name and position, not just by a remembered number.
3. Confirm the exact `mkvpropedit` track selector for the installed MKVToolNix version and target file.
4. Draft a command that changes only requested properties. Consult `references/track-properties.md` for the property-to-JSON mapping used in verification.
5. Explain that this is an in-place edit. An explicit request for this change on a specific file authorizes execution; ask for confirmation only if the target, selection, or consequences are ambiguous or the change exceeds the request.
6. After authorized execution, verify the edited properties using `mkvmerge -J` or another suitable inspection method.

## Track selector caution

The archive uses selectors such as `track:a1`, `track:a2`, `track:s1`, and `track:s2`. These are MKVToolNix selector conventions, not FFmpeg stream specifiers. Do not transfer FFmpeg's zero-based `0:a:0` or `0:s:1` directly into an `mkvpropedit` command. Inspect the MKVToolNix track list and confirm selector syntax for the installed version.

## Common properties

- `--set language=eng` or `--set language=kor`
- `--set name="English"` or a descriptive audio title
- `--set flag-default=1` / `--set flag-default=0`
- `--set flag-hearing-impaired=1` / `--set flag-hearing-impaired=0`

Set hearing-impaired only for a track intended for SDH/HI viewers. Do not set multiple subtitle tracks as default unless explicitly requested and understood. The default flag is a playback preference, not a guarantee every player will select the track.

## Combine changes

Compatible changes to one track can be combined in one edit block, for example:

```bash
mkvpropedit "INPUT.mkv" \
  --edit track:a1 \
  --set language=eng \
  --set flag-default=1 \
  --set name="EAC3 5.1 @ 256 kbps"
```

This is a template only. Verify track `a1` is the intended audio track and verify codec/bitrate/layout before applying a descriptive title.

For an English SDH subtitle:

```bash
mkvpropedit "INPUT.mkv" \
  --edit track:s2 \
  --set language=eng \
  --set flag-hearing-impaired=1 \
  --set name="English SDH"
```

Only use `track:s2` if inspection confirms it is the intended second subtitle under the selector convention in use.

## Refresh track statistics without remuxing

If only statistics need refreshing, use:

```bash
mkvpropedit "INPUT.mkv" --add-track-statistics-tags
```

This reads the media to calculate statistics and updates tags in place; it does not remux or re-encode streams. Inspect the resulting per-track statistics tags. If tracks must also be removed or the user explicitly requests `mkvmerge`, use `../mkv-remux-validation/SKILL.md` instead; `mkvmerge` generates track statistics by default, so a separate refresh is normally unnecessary.

## Safety

- `mkvpropedit` modifies the target in place. Prefer making a backup or a separate copy if rollback matters.
- Never use an empty target path such as `mkvpropedit ""`.
- Do not apply a remembered track selector across a folder unless each file's track layout has been inspected and verified.
- For a batch, preview the file list, per-file target track, and changes; then ask for approval before execution.
