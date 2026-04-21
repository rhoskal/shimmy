open Cmdliner
open Shimmy

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

let run filepath : (unit, string) result =
  match Ffprobe.probe_media_file filepath with
  | Error msg ->
      Printf.eprintf "Error probing file: %s\n%!" msg;
      Error msg
  | Ok result -> (
      let audio_streams = Ffprobe.audio_streams result in

      (* Find first EAC-3 8-channel (7.1) stream *)
      let target_stream_opt =
        List.find_opt
          (fun (stream : Ffprobe.audio_stream) ->
            stream.codec_name = "eac3" && stream.channels = Some 8)
          audio_streams
      in
      match target_stream_opt with
      | None ->
          Error "Could not find a single EAC-3 7.1 (8-channel) audio stream"
      | Some stream -> (
          match (stream.language, stream.bitrate) with
          | None, _ -> Error "Undefined language for the target audio stream"
          | _, None -> Error "Undefined bitrate for the target audio stream"
          | Some lang, Some bitrate -> (
              Printf.printf
                "[INFO] Found EAC-3 7.1 stream: index=%d, lang=%s, bitrate=%d\n\
                 %!"
                stream.index lang bitrate;

              (* Create temp output file next to input *)
              let dir = Filename.dirname filepath in
              let base = Filename.basename filepath in
              let name, ext =
                try
                  let dot = String.rindex base '.' in
                  ( String.sub base 0 dot,
                    String.sub base dot (String.length base - dot) )
                with Not_found -> (base, "")
              in
              let temp_file =
                Filename.concat dir (Printf.sprintf "%s_downmixed%s" name ext)
              in

              Printf.printf "Running FFmpeg...\n!";

              (* Build FFmpeg command *)
              let bitrate_k = Printf.sprintf "%d" (bitrate / 1000) in
              let ffmpeg_argv =
                [|
                  Printf.sprintf "ffmpeg -i %s" filepath;
                  "-loglevel fatal";
                  "-map 0:v:0 -c:v copy";
                  "-map 0:a:0 -c:a:0 copy";
                  Printf.sprintf "-map 0:a:0 -c:a:1 eac3 -b:a:1 %sk -ac:a:1 6"
                    bitrate_k;
                  "-map 0:s? -c:s copy";
                  "-map_chapters 0";
                  "-metadata:s:a:0";
                  Printf.sprintf "title=EAC3 7.1 @ %s kbps" bitrate_k;
                  "-metadata:s:a:1";
                  Printf.sprintf "title=EAC3 5.1 @ %s kbps" bitrate_k;
                  "-metadata:s:a:1";
                  Printf.sprintf "language=%s" lang;
                  temp_file;
                |]
              in

              match run_command ffmpeg_argv with
              | Ok () ->
                  Printf.printf
                    "\nFFmpeg completed successfully.\nOutput file: %s\n%!"
                    temp_file;
                  Ok ()
              | Error msg ->
                  Printf.eprintf "FFmpeg failed: %s\n%!" msg;
                  Error msg)))

let file_arg =
  let doc = "Path to the media file" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~docv:"PATH" ~doc)

let cmd =
  let doc = "Replace EAC-3 7.1 with EAC-3 5.1" in
  let info = Cmd.info "downmix" ~doc in

  Cmd.make info Term.(const run $ file_arg)
