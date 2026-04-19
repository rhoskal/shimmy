open Cmdliner

let run () : (unit, string) result =
  print_endline "downmix command - not implemented yet";
  Ok ()

let cmd =
  let doc = "Replace EAC-3 7.1 with EAC-3 5.1" in
  let info = Cmd.info "downmix" ~doc in

  Cmd.make info Term.(const run $ const ())
