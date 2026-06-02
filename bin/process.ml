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
