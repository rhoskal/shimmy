open Cmdliner

let version = "0.1.0"

let info =
  let doc = "Audio stream compatibility for Apple devices" in
  Cmd.info "shimmy" ~version ~doc ~exits:[]
    ~man:
      [
        `S Manpage.s_bugs;
        `P "Report bugs at https://codeberg.org/rhoskal/shimmy/issues";
      ]

let cmds =
  [
    Cmd_downmix.cmd;
    Cmd_dts.cmd;
    Cmd_dtshd.cmd;
    Cmd_dtsx.cmd;
    Cmd_truehd.cmd;
    Cmd_probe.cmd;
  ]

let main_cmd =
  let default = Term.(ret (const (`Help (`Auto, None)))) in
  Cmd.group info ~default cmds

let main () = Cmd.eval_result main_cmd
let () = if !Sys.interactive then () else exit (main ())
