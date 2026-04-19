(** Module for locating external binaries (ffprobe, ffmpeg, mkvmerge) *)

val ffprobe_path : unit -> string
val ffmpeg_path : unit -> string
val mkvmerge_path : unit -> string

val check_all : unit -> unit
(** [check_all ()] can be called at startup to verify all tools are available.
    Raises a clear error if any are missing. *)
