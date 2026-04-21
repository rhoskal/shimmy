open Cmdliner

let run () : (unit, string) result =
  print_endline "dts command - not implemented yet";
  Ok ()

let cmd =
  let doc = "Convert DTS audio stream to be EAC3" in
  let info = Cmd.info "dts" ~doc in

  Cmd.make info Term.(const run $ const ())
