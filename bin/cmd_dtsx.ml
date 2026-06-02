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

let format_audio_title (stream : Ffprobe.Audio.t) : string =
  let base = "DTS-X" in

  match stream.channel_layout with
  | None -> base
  | Some Mono -> Printf.sprintf "%s 1.0" base
  | Some Stereo -> Printf.sprintf "%s 2.0" base
  | Some Surround_3_0 -> Printf.sprintf "%s 3.0" base
  | Some Surround_5_1 -> Printf.sprintf "%s 5.1" base
  | Some Surround_7_1 -> Printf.sprintf "%s 7.1" base
  | Some Surround_9_1 -> Printf.sprintf "%s 9.1" base
  | Some (Unknown s) -> Printf.sprintf "%s %s" base s

let is_dts_x (stream : Ffprobe.Audio.t) =
  let re = Re.compile (Re.str "DTS:X") in
  match stream.profile with
  | None -> false
  | Some p -> stream.codec_name = "dts" && Re.execp re p

let run filepath : (unit, string) result =
  let open Result_syntax in
  (* 1. Probe *)
  let* probe = Ffprobe.probe_media_file filepath in

  let audio_streams = Ffprobe.audio_streams probe in

  (* 2. Find target stream *)
  let* stream =
    match List.find_opt is_dts_x audio_streams with
    | None -> Error "Could not find a DTS audio stream"
    | Some s -> Ok s
  in

  (* 3. Validate metadata *)
  let* lang =
    match stream.language with
    | None -> Error "Target stream has no language tag"
    | Some l -> Ok l
  in

  Printf.printf "[-] Found DTS stream: index=%d, lang=%s\n%!" stream.index lang;

  (* 4. Prepare filenames *)
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

  (* 5. Build and run FFmpeg *)
  let bitrate_k = string_of_int 1536 in

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
      "-c:a:0";
      "copy";
      "-map";
      "0:a:0";
      "-c:a:1";
      "eac3";
      "-b:a:1";
      bitrate_k ^ "k";
      "-ac:a:1";
      "6";
      "-map";
      "0:s?";
      "-c:s";
      "copy";
      "-map_chapters";
      "0";
      "-metadata:s:a:0";
      Printf.sprintf "title=%s" (format_audio_title stream);
      "-metadata:s:a:1";
      Printf.sprintf "title=EAC3 5.1 @ %s kbps" bitrate_k;
      "-metadata:s:a:1";
      Printf.sprintf "language=%s" lang;
      "-disposition:a:1";
      "0";
      temp_file;
    |]
  in

  Printf.printf "[+] Running ffmpeg...\n%!";
  let* () = Process.run_command ffmpeg_argv in

  (* 6. Run mkvmerge *)
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
  let doc = "Append EAC3 5.1 audio stream for compatibility" in
  let info = Cmd.info "dtsx" ~doc in

  Cmd.make info Term.(const run $ file_arg)
