---
name: media-processing
description: Route requests involving FFmpeg, MKVToolNix, MKV stream selection, subtitle handling, track metadata, remuxing, trimming, or batch processing to the appropriate specialist skill. Use when planning or reviewing media commands.
---

# Media Processing Router

Use this skill to classify the requested media task and delegate to the narrowest applicable skill. Apply the authorization policy below before executing media-changing commands.

## Route by intent

- Selecting/removing existing MKV tracks without conversion: `mkv-remux-validation`; prefer `mkvmerge`, especially when remuxing or regenerating statistics is also requested.
- FFmpeg stream mapping/copying, codec conversion, subtitle extraction/insertion, or timestamp trimming: `mkv-stream-operations`
- Editing existing Matroska track names, languages, default flags, hearing-impaired flags, or refreshing statistics without remuxing: `mkv-metadata`
- Remuxing Matroska or verifying container/track results: `mkv-remux-validation`
- Applying an operation to many files, recursive directory traversal, or multi-step pipelines: `batch-media-processing` plus the relevant specialist skill

If a request spans categories, use multiple relevant skills. Keep the workflow as small as possible; do not add a remux stage unless it serves a stated goal.

## Mandatory interaction policy

1. Restate the intended changes briefly, including which streams should remain, change, or be removed.
2. Inspect available file metadata when possible. If inspection cannot be performed, ask the user for `ffprobe` or `mkvmerge -J` output, or clearly mark assumptions.
3. Draft the exact command with concrete input and output paths, and explain any consequential behavior such as re-encoding, stream-copy cutting, or in-place editing. For an already authorized, straightforward operation, a brief execution notice is sufficient; do not require another approval round solely to show command syntax.
4. An explicit request to modify a specific file authorizes the requested change once inspection identifies the target unambiguously. This includes narrow in-place metadata edits with `mkvpropedit`. A general request for advice, examples, or a review is not execution authorization. Ask for confirmation when the target, track selection, or consequences are ambiguous, or when the proposed operation goes beyond the request.
5. Prefer a new output path for remuxing/conversion. Never overwrite an existing output, replace an input with a remuxed/converted file, or delete an original without specific approval. Broad batch changes require approval of a concrete plan under `batch-media-processing`; approval of a single-file operation does not authorize a batch.
6. After authorized execution, validate the output and report the actual result. If execution is unavailable, provide commands and validation steps for the user to run.

## Shared safety rules

- Quote every path that may contain spaces or shell metacharacters.
- Use placeholders only in examples; do not submit an empty filename such as `mkvpropedit ""`.
- Do not guess stream indexes, codec properties, subtitle type, or track flags based on a different file or filename.
- Distinguish FFmpeg input stream indexes (zero-based) from output stream indexes (zero-based) and MKVToolNix track IDs/selectors (as reported by MKVToolNix; commonly presented as one-based track selectors in `mkvpropedit` examples). Confirm with inspection.
- Preserve chapters and metadata only when intended and supported. Verify what survives each remux.
- Prefer stream copy for streams that should remain unchanged. Explicitly identify every stream being converted.
- Track titles are labels, not verification of codec, bitrate, channels, or language.
- A successful exit status does not establish that the resulting file has the desired tracks or metadata.
- Avoid shell glob syntax unless the shell is known. The archive's `**/*.mkv(.)` syntax is Zsh-specific.
- For batch work, preview the exact file list and planned output paths, check for collisions, and ask for approval before running.
