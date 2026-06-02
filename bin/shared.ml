open Shimmy

let is_atmos (stream : Ffprobe.Audio.t) : bool =
  let re = Re.compile (Re.str "Atmos") in

  match stream.profile with
  | None -> false
  | Some profile -> Re.execp re profile

let is_dts_hd_ma (stream : Ffprobe.Audio.t) : bool =
  match stream.profile with
  | Some "DTS-HD MA" -> stream.codec_name = "dts"
  | _ -> false

let is_dts_x (stream : Ffprobe.Audio.t) =
  let re = Re.compile (Re.str "DTS:X") in

  match stream.profile with
  | None -> false
  | Some p -> stream.codec_name = "dts" && Re.execp re p

let is_dts (stream : Ffprobe.Audio.t) : bool = stream.codec_name = "dts"
let is_truehd (stream : Ffprobe.Audio.t) : bool = stream.codec_name = "truehd"
let is_eac3 (stream : Ffprobe.Audio.t) : bool = stream.codec_name = "eac3"

let format_audio_title (stream : Ffprobe.Audio.t) : string =
  let base =
    match stream.codec_name with
    | "aac" -> "AAC"
    | "eac3" -> "EAC3"
    | "dts" ->
        if is_dts_hd_ma stream then "DTS-HD MA"
        else if is_dts_x stream then "DTS-X"
        else "DTS"
    | "truehd" -> "TrueHD"
    | _ -> "UNKNOWN"
  in
  let with_atmos = if is_atmos stream then base ^ " Atmos" else base in

  match stream.channel_layout with
  | None -> with_atmos
  | Some Mono -> Printf.sprintf "%s Mono" with_atmos
  | Some Stereo -> Printf.sprintf "%s Stereo" with_atmos
  | Some Surround_3_0 -> Printf.sprintf "%s 3.0" with_atmos
  | Some Surround_5_1 -> Printf.sprintf "%s 5.1" with_atmos
  | Some Surround_7_1 -> Printf.sprintf "%s 7.1" with_atmos
  | Some Surround_9_1 -> Printf.sprintf "%s 9.1" with_atmos
  | Some (Unknown s) -> Printf.sprintf "%s %s" with_atmos s

let bitrate_k (stream : Ffprobe.Audio.t) : string =
  match stream.bitrate with
  | None -> string_of_int 0
  | Some b when b < 1536000 ->
      string_of_int (int_of_float (Float.ceil (float_of_int b /. 1000.0)))
  | _ -> string_of_int 1536

let normalized_codec (stream : Ffprobe.Audio.t) : string =
  String.uppercase_ascii stream.codec_name
