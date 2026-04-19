let find_in_path name =
  match Sys.getenv_opt "PATH" with
  | None -> None
  | Some path_env ->
      let paths = String.split_on_char ':' path_env in
      List.find_opt
        (fun dir ->
          let full = Filename.concat dir name in
          Sys.file_exists full && not (Sys.is_directory full))
        paths
      |> Option.map (fun dir -> Filename.concat dir name)

let get_path ~prog =
  match find_in_path prog with
  | Some p -> p
  | None -> (
      match Sys.getenv_opt (String.uppercase_ascii prog ^ "_PATH") with
      | Some p when p <> "" -> p
      | _ ->
          failwith
            (Printf.sprintf
               "Could not find '%s' in $PATH. Please install it or set %s_PATH \
                environment variable."
               prog
               (String.uppercase_ascii prog)))

(* Cached values - computed once *)
let ffprobe = lazy (get_path ~prog:"ffprobe")
let ffmpeg = lazy (get_path ~prog:"ffmpeg")
let mkvmerge = lazy (get_path ~prog:"mkvmerge")
let ffprobe_path () = Lazy.force ffprobe
let ffmpeg_path () = Lazy.force ffmpeg
let mkvmerge_path () = Lazy.force mkvmerge

let check_all () =
  ignore (ffprobe_path ());
  ignore (ffmpeg_path ());
  ignore (mkvmerge_path ())
