open Cmdliner

let run () : (unit, string) result =
  print_endline "truehd command - not implemented yet";
  Ok ()

let cmd =
  let doc = "Append EAC-3 audio stream for compatibility" in
  let info = Cmd.info "truehd" ~doc in

  Cmd.make info Term.(const run $ const ())
