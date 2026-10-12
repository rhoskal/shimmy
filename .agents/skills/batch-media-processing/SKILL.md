---
name: batch-media-processing
description: Plan safe shell loops and multi-step FFmpeg/MKVToolNix workflows across multiple MKV files. Use for folder-wide processing, recursive file discovery, season batches, or repeated metadata edits.
---

# Batch Media Processing

This skill coordinates multiple media operations. It does not override the specialist skill for the actual FFmpeg, `mkvpropedit`, or `mkvmerge` operation.

## Approval-first policy

Before executing a batch, show:
- the exact file list or a reliable preview command;
- the operation planned for each file;
- the output path for each file;
- any in-place modifications;
- the collision/overwrite behavior;
- the validation and failure policy.

Ask for approval of that plan. Do not infer approval for a batch from approval of a single-file example.

## Shell and path safety

- Determine the active shell before using shell-specific glob syntax.
- The source archive uses Zsh recursive globs such as `**/*.mkv(.)`; `(.)` is a Zsh glob qualifier for plain files and is not portable to Bash.
- Quote path variables: `"$file"`, not `$file`.
- Avoid parsing `ls` output or splitting filenames on whitespace.
- Do not silently follow symlinks or traverse unexpected directories.
- Define whether matching is case-sensitive and whether nested directories are included.
- Check output names for collisions before processing.
- Avoid overwriting source files; write to a distinct path by default.

## Preview before execution

For a known Zsh environment, a preview can be drafted like this:

```zsh
for file in /path/to/input/**/*.mkv(.N); do
  printf '%s\n' "$file"
done
```

The `.N` qualifier makes an unmatched glob expand to no results in Zsh. This example is Zsh-specific. Confirm the shell and desired recursion before use.

For portability, use a shell-appropriate null-delimited file traversal rather than assuming Zsh syntax is available. Read-only discovery, inspection, and previews may run without an extra approval round. Modifying loops still require approval of the concrete batch plan above.

## Per-file workflow

1. Enumerate and display candidate files.
2. Inspect each file's stream/track layout before selecting tracks or applying track selectors.
3. Calculate output names and detect collisions.
4. Draft commands for one representative file.
5. Obtain approval of the concrete batch plan before executing modifying commands. Once that plan is approved, do not ask again for each file or step within its scope.
6. Process one file at a time and capture each exit status.
7. Validate each output before marking that file successful.
8. Stop or continue according to an explicitly stated failure policy.
9. Report per-file successes, failures, skipped files and outputs.

## Multi-step pipelines

If FFmpeg output is followed by `mkvmerge`, document the reason for both steps and use distinct intermediate/final paths. Check the first step's exit status before invoking the second. Avoid leaving ambiguous temporary files; only clean up intermediates after validation and explicit authorization for deletion.

## Metadata batches

Do not apply `track:a1`, `track:s1`, or `track:s2` to every file on the assumption that track layouts match. Inspect each file or validate a consistent cohort before applying changes. If any file differs, stop and request a decision rather than applying the wrong metadata to a different track.
