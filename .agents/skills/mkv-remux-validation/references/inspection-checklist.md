# MKV Inspection and Validation Checklist

## Read-only inspection commands

FFprobe summary:

```bash
ffprobe -v error \
  -show_entries format=filename,duration,size:stream=index,codec_type,codec_name,profile,channels,channel_layout,bit_rate:stream_tags=language,title \
  -show_entries stream_disposition \
  -of json "FILE.mkv"
```

MKVToolNix JSON inspection:

```bash
mkvmerge -J "FILE.mkv"
```

Use both where needed. FFprobe and MKVToolNix may expose different identifiers and fields; do not equate their track IDs without a verified mapping.

## Acceptance checklist

### File integrity
- [ ] Output path is the intended path.
- [ ] Output exists and is non-empty.
- [ ] The command completed successfully.
- [ ] Original file remains unchanged unless overwrite was explicitly approved.

### Streams
- [ ] Video stream count/order and codec match the plan.
- [ ] Audio stream count/order and codecs match the plan.
- [ ] Subtitle stream count/order and codecs match the plan.
- [ ] Required attachments/data streams were preserved or intentionally omitted.
- [ ] No unwanted stream was accidentally included.

### Metadata and flags
- [ ] Language codes are correct.
- [ ] Track titles/names are correct.
- [ ] Default flags match the requested playback behavior.
- [ ] Forced flags are preserved/set as intended.
- [ ] Hearing-impaired flags are correct for SDH tracks. In `mkvmerge -J`, the key is `flag_hearing_impaired`, not `hearing_impaired`; an absent key indicates an unset flag. See `../../mkv-metadata/references/track-properties.md` for other property mappings.
- [ ] When statistics regeneration was requested, per-track statistics tags are present and reflect the operation (including the statistics writing application/date and bitrate/duration/frame/byte counts).
- [ ] Chapters and relevant global metadata are preserved as intended.

### Timing and quality
- [ ] Duration is consistent with the requested trim.
- [ ] Video begins/ends at acceptable points for the requested cut type.
- [ ] Audio and subtitles remain synchronized.
- [ ] Converted audio has the intended codec, channels/layout and actual bitrate behavior.
- [ ] A playback check is performed when practical, especially after timestamp edits or subtitle insertion.

## Reporting

Summarize:
1. command run (or command prepared if not approved);
2. output path;
3. streams and properties verified;
4. any deviations or checks not performed.

Do not say “all good” if playback, synchronization, or a requested property was not actually checked.
