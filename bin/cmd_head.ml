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

let is_atmos (stream : Ffprobe.Audio.t) : bool =
  let re = Re.compile (Re.str "Atmos") in
  match stream.profile with
  | None -> false
  | Some profile -> Re.execp re profile

let is_dts_hd_ma (stream : Ffprobe.Audio.t) =
  stream.codec_name = "dts"
  && match stream.profile with Some "DTS-HD MA" -> true | _ -> false

let format_audio_title (stream : Ffprobe.Audio.t) : string =
  let base =
    match stream.codec_name with
    | "aac" -> "AAC"
    | "eac3" -> "EAC3"
    | "dts" -> if is_dts_hd_ma stream then "DTS-HD MA" else "DTS"
    | "truehd" -> "TrueHD"
    | _ -> "UNKNOWN"
  in
  let with_atmos = if is_atmos stream then base ^ " Atmos" else base in

  match stream.channel_layout with
  | None -> with_atmos
  | Some Mono -> Printf.sprintf "%s Mono" with_atmos
  | Some Stereo -> Printf.sprintf "%s Stereo" with_atmos
  | Some Surround_3_0 -> Printf.sprintf "%s 3.0" with_atmos
  | Some Surround_5_1 -> Printf.sprintf "%s 5.1" with_atmos
  | Some Surround_7_1 -> Printf.sprintf "%s 7.1" with_atmos
  | Some Surround_9_1 -> Printf.sprintf "%s 9.1" with_atmos
  | Some (Unknown s) -> Printf.sprintf "%s %s" with_atmos s

let run filepath : (unit, string) result =
  let open Result_syntax in
  (* Probe *)
  let* probe = Ffprobe.probe_media_file filepath in

  let audio_streams = Ffprobe.audio_streams probe in

  (* Find target stream *)
  let* stream =
    match audio_streams with
    | [] -> Error "Failed to get first audio stream"
    | x :: _ -> Ok x
  in

  (* Validate metadata *)
  let* lang =
    match stream.language with
    | None -> Error "Target stream has no language tag"
    | Some l -> Ok l
  in

  Printf.printf "[-] Found %s stream: index=%d, lang=%s\n%!" stream.codec_name
    stream.index lang;

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
  let bitrate_k =
    match stream.bitrate with
    | None -> string_of_int 0
    | Some b when b < 1536000 ->
        string_of_int (int_of_float (Float.ceil (float_of_int b /. 1000.0)))
    | _ -> string_of_int 1536
  in

  let codec = String.uppercase_ascii stream.codec_name in

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
