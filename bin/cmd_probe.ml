open Cmdliner
open Shimmy

let run filepath : (unit, string) result =
  match Ffprobe.probe_media_file filepath with
  | Error msg ->
      Printf.eprintf "Error: %s\n%!" msg;
      Error msg
  | Ok probe ->
      Output.print_probe_result probe;
      Ok ()

let file_arg =
  let doc = "Path to the media file" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~docv:"PATH" ~doc)

let cmd =
  let doc = "Probe a media file and display stream information" in
  let info = Cmd.info "probe" ~doc in

  Cmd.make info Term.(const run $ file_arg)
