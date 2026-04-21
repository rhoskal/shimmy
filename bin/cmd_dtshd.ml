open Cmdliner

let run () : (unit, string) result =
  print_endline "dtshd command - not implemented yet";
  Ok ()

let cmd =
  let doc = "Append EAC3 audio stream for compatibility" in
  let info = Cmd.info "dtshd" ~doc in

  Cmd.make info Term.(const run $ const ())
