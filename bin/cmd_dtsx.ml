open Cmdliner

let run () : (unit, string) result =
  print_endline "dtsx command - not implemented yet";
  Ok ()

let cmd =
  let doc = "Append EAC-3 audio stream for compatibility" in
  let info = Cmd.info "dtsx" ~doc in

  Cmd.make info Term.(const run $ const ())
