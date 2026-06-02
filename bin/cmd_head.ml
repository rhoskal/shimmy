open Cmdliner
open Shimmy

let mk_final_filename (path : string) : string =
  let dir = Filename.dirname path in
  let base = Filename.basename path in
  let name, ext =
    try
      let dot = String.rindex base '.' in
      let stem = String.sub base 0 dot in
      let ext = String.sub base dot (String.length base - dot) in
      (stem, ext)
    with Not_found -> (base, "")
  in
  (* Remove old release group: everything after the last '-' before the extension *)
  let clean_name =
    try
      let last_dash = String.rindex name '-' in
      String.sub name 0 last_dash
    with Not_found -> name
  in
  Filename.concat dir (clean_name ^ "-rhoskal" ^ ext)

let run filepath : (unit, string) result =
  let open Result_syntax in
  (* Probe *)
  let* probe = Ffprobe.probe_media_file filepath in

  (* Find target stream *)
  let* stream =
    match Ffprobe.audio_streams probe with
    | [] -> Error "Failed to get first audio stream"
    | x :: _ -> Ok x
  in

  (* Validate metadata *)
  let* lang =
    Option.to_result ~none:"Target stream has no language tag" stream.language
  in

  let* bitrate =
    Option.to_result ~none:"Target stream has no bitrate" stream.bitrate
  in

  Printf.printf "[-] Found %s stream @ index=%d with lang=%s\n%!"
    stream.codec_name stream.index lang;

  (* Prepare filenames *)
  let dir = Filename.dirname filepath in
  let base = Filename.basename filepath in
  let name, ext =
    try
      let dot = String.rindex base '.' in
      (String.sub base 0 dot, String.sub base dot (String.length base - dot))
    with Not_found -> (base, "")
  in
  let temp_file = Filename.concat dir (Printf.sprintf "%s_temp%s" name ext) in
  let final_file = mk_final_filename filepath in

  (* Build and run FFmpeg *)
  let bitrate_k = Shared.bitrate_k stream in
  let codec = Shared.normalized_codec stream in

  let* channel_layout =
    match stream.channel_layout with
    | None -> Error "No channel layout detected"
    | Some Mono -> Ok "Mono"
    | Some Stereo -> Ok "Stereo"
    | Some Surround_3_0 -> Ok "3.0"
    | Some Surround_5_1 -> Ok "5.1"
    | Some Surround_7_1 -> Ok "7.1"
    | Some Surround_9_1 -> Ok "9.1"
    | Some (Unknown x) ->
        Error (Printf.sprintf "Unknown channel layout found: %s" x)
  in

  let ffmpeg_argv =
    [|
      "ffmpeg";
      "-i";
      filepath;
      "-loglevel";
      "fatal";
      "-map";
      "0:v:0";
      "-c:v";
      "copy";
      "-map";
      "0:a:0";
      "-c:a";
      "copy";
      "-map";
      "0:s?";
      "-c:s";
      "copy";
      "-map_chapters";
      "0";
      "-metadata:s:a:0";
      Printf.sprintf "title=%s %s @ %s kbps" codec channel_layout bitrate_k;
      "-metadata:s:a:0";
      Printf.sprintf "language=%s" lang;
      "-disposition:a:0";
      "1";
      temp_file;
    |]
  in

  Printf.printf "[+] Running ffmpeg...\n%!";
  let* () = Process.run_command ffmpeg_argv in

  (* Run mkvmerge *)
  let mkvmerge_argv =
    [| "mkvmerge"; "--quiet"; "--output"; final_file; temp_file |]
  in

  Printf.printf "[+] Running mkvmerge...\n%!";
  let* () = Process.run_command mkvmerge_argv in

  Printf.printf "[✓] Success! Final file: %s\n%!" final_file;

  (* Cleanup *)
  ignore (Sys.command (Printf.sprintf "rm -f %s" (Filename.quote temp_file)));

  Ok ()

let file_arg =
  let doc = "Path to the media file" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~docv:"PATH" ~doc)

let cmd =
  let doc = "Keep first audio stream and drop the others" in
  let info = Cmd.info "head" ~doc in

  Cmd.make info Term.(const run $ file_arg)
