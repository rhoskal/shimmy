open Cmdliner
open Shimmy

module Result_syntax = struct
  let ( let* ) = Result.bind
end

(** Run a command with proper signal forwarding so Ctrl-C works cleanly *)
let run_command (argv : string array) : (unit, string) result =
  try
    let pid =
      Unix.create_process argv.(0) argv Unix.stdin Unix.stdout Unix.stderr
    in
    match Unix.waitpid [] pid with
    | _, Unix.WEXITED 0 -> Ok ()
    | _, Unix.WEXITED n ->
        Error (Printf.sprintf "Command failed with exit code %d" n)
    | _, Unix.WSIGNALED s ->
        let sig_name =
          match s with
          | 2 -> "SIGINT"
          | 9 -> "SIGKILL"
          | 15 -> "SIGTERM"
          | n -> Printf.sprintf "signal %d" n
        in
        Error (Printf.sprintf "Command killed by %s" sig_name)
    | _, Unix.WSTOPPED _ -> Error "Command stopped"
  with
  | Unix.Unix_error (err, fn, arg) ->
      Error
        (Printf.sprintf "Unix error in %s(%s): %s" fn arg
           (Unix.error_message err))
  | e -> Error (Printexc.to_string e)

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

let is_dts (s : Ffprobe.audio_stream) = s.codec_name = "dts"

let run filepath : (unit, string) result =
  let open Result_syntax in
  (* 1. Probe *)
  let* probe = Ffprobe.probe_media_file filepath in

  let audio_streams = Ffprobe.audio_streams probe in

  (* 2. Find target stream *)
  let* stream =
    match List.find_opt is_dts audio_streams with
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
  let bitrate_k =
    match stream.bitrate with
    | None -> string_of_int 0
    | Some b when b < 1536000 -> string_of_int (b / 1000)
    | _ -> string_of_int 1536
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
      "eac3";
      "-b:a";
      bitrate_k ^ "k";
      "-ac";
      "6";
      "-map";
      "0:s?";
      "-c:s";
      "copy";
      "-map_chapters";
      "0";
      "-metadata:s:a:0";
      Printf.sprintf "title=EAC3 5.1 @ %s kbps" bitrate_k;
      "-metadata:s:a:0";
      Printf.sprintf "language=%s" lang;
      temp_file;
    |]
  in

  Printf.printf "[+] Running ffmpeg...\n%!";
  let* () = run_command ffmpeg_argv in

  (* 6. Run mkvmerge *)
  let mkvmerge_argv =
    [| "mkvmerge"; "--quiet"; "--output"; final_file; temp_file |]
  in

  Printf.printf "[+] Running mkvmerge...\n%!";
  let* () = run_command mkvmerge_argv in

  Printf.printf "[✓] Success! Final file: %s\n%!" final_file;

  (* Cleanup *)
  ignore (Sys.command (Printf.sprintf "rm -f %s" (Filename.quote temp_file)));
  Ok ()

let file_arg =
  let doc = "Path to the media file" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~docv:"PATH" ~doc)

let cmd =
  let doc = "Convert DTS audio stream to be EAC3" in
  let info = Cmd.info "dts" ~doc in

  Cmd.make info Term.(const run $ file_arg)
