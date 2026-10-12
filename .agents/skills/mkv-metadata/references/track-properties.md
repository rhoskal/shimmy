# MKVToolNix Track Property Reference

## User conventions from the command archive

| Intended track | Language | Name | Flags |
|---|---|---|---|
| English audio | `eng` | e.g. `EAC3 5.1 @ 256 kbps` | Default only if requested |
| Korean audio | `kor` | e.g. `EAC3 Atmos 5.1 @ 768 kbps` | Default only if requested |
| English subtitle | `eng` | `English` | Default only if requested |
| English SDH subtitle | `eng` | `English SDH` | `flag-hearing-impaired=1`; default only if requested |

Names and bitrates above are examples of a naming convention. They must be checked against actual stream properties.

## Inspect first

```bash
mkvmerge -J "INPUT.mkv"
```

Use the JSON output to identify tracks, track IDs, track type, codec, language, name, and flags. Read the installed MKVToolNix documentation if selector interpretation is unclear. Do not infer `track:s2` from FFmpeg's `0:s:1`.

## Property names in commands versus inspection JSON

`mkvpropedit` property names are not always the keys returned by `mkvmerge -J`:

| `mkvpropedit` property | `mkvmerge -J` key in track `properties` |
|---|---|
| `name` | `track_name` |
| `language` | `language` |
| `flag-default` | `default_track` |
| `flag-forced` | `forced_track` |
| `flag-hearing-impaired` | `flag_hearing_impaired` |

An unset flag may be absent from the JSON. For flags such as `flag_hearing_impaired`, treat an absent key as false when checking the effective state (for example, `properties.get("flag_hearing_impaired", False)` in Python). After explicitly enabling the flag, verify that the key is present and true. Do not assume every missing flag defaults to false: Matroska's default-track flag defaults to true. Consult the installed schema/documentation if other fields are missing or differ.

## Example: set language/name and default flag

```bash
mkvpropedit "INPUT.mkv" \
  --edit track:a1 \
  --set language=eng \
  --set flag-default=1 \
  --set name="EAC3 5.1 @ 256 kbps"
```

## Example: clear default on another audio track

```bash
mkvpropedit "INPUT.mkv" \
  --edit track:a2 \
  --set flag-default=0
```

## Example: English subtitle and English SDH subtitle

```bash
mkvpropedit "INPUT.mkv" \
  --edit track:s1 \
  --set language=eng \
  --set flag-default=1 \
  --set name="English" \
  --edit track:s2 \
  --set language=eng \
  --set flag-hearing-impaired=1 \
  --set name="English SDH"
```

This combines edits in one invocation. Before using it, confirm that both selectors refer to the intended subtitle tracks and that the default flag on the English track is desired. Set or clear the SDH default separately if required.

## Verify after editing

Run `mkvmerge -J "INPUT.mkv"` again and compare each target track's language, name, default flag and hearing-impaired flag with the requested values. If the installed tool's JSON schema or displayed identifiers differ, follow that version's documentation rather than guessing.
