open Yojson.Basic.Util

type stream_type = Video | Audio | Subtitle | Data

type video_stream = {
  index : int;
  avg_frame_rate : string option;
  codec_name : string;
  duration : float option;
  height : int;
  language : string option;
  profile : string option;
  width : int;
}

type audio_stream = {
  index : int;
  bitrate : int option;
  channels : int option;
  codec_name : string;
  duration : float option;
  language : string option;
  profile : string option;
  sample_rate : int option;
}

type subtitle_stream = {
  index : int;
  codec_name : string;
  language : string option;
}

type data_stream = { index : int; codec_name : string }

type stream =
  | Video of video_stream
  | Audio of audio_stream
  | Subtitle of subtitle_stream
  | Data of data_stream

type format_info = { filename : string; size : int option }
type probe_result = { streams : stream list; format : format_info }

(* ===================== *)
(* Helpers               *)
(* ===================== *)

let get_video_streams result =
  List.filter_map (function Video v -> Some v | _ -> None) result.streams

let get_audio_streams result =
  List.filter_map (function Audio a -> Some a | _ -> None) result.streams

let get_subtitle_streams result =
  List.filter_map (function Subtitle s -> Some s | _ -> None) result.streams

(* ===================== *)
(* Parsers               *)
(* ===================== *)

let get_language json =
  match member "tags" json with
  | `Assoc tags -> (
      try
        match List.assoc_opt "language" tags with
        | Some (`String lang) -> Some lang
        | _ -> None
      with Not_found -> None)
  | _ -> None

let parse_video_stream json : video_stream =
  {
    index = json |> member "index" |> to_int;
    avg_frame_rate = json |> member "r_frame_rate" |> to_string_option;
    codec_name = json |> member "codec_name" |> to_string;
    duration = json |> member "duration" |> to_float_option;
    height = json |> member "height" |> to_int;
    language = get_language json;
    profile = json |> member "profile" |> to_string_option;
    width = json |> member "width" |> to_int;
  }

let parse_audio_stream json : audio_stream =
  {
    index = json |> member "index" |> to_int;
    bitrate =
      json |> member "bit_rate" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
    channels = json |> member "channels" |> to_int_option;
    codec_name = json |> member "codec_name" |> to_string;
    duration = json |> member "duration" |> to_float_option;
    language = get_language json;
    profile = json |> member "profile" |> to_string_option;
    sample_rate =
      json |> member "sample_rate" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
  }

let parse_subtitle_stream json : subtitle_stream =
  {
    index = json |> member "index" |> to_int;
    codec_name = json |> member "codec_name" |> to_string;
    language = get_language json;
  }

let parse_data_stream json : data_stream =
  {
    index = json |> member "index" |> to_int;
    codec_name = json |> member "codec_name" |> to_string;
  }

let parse_format json =
  {
    filename = json |> member "filename" |> to_string;
    size =
      json |> member "size" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
  }

let parse_stream json =
  let codec_type_str =
    match member "codec_type" json with `String s -> s | _ -> "unknown"
  in

  match codec_type_str with
  | "video" -> Video (parse_video_stream json)
  | "audio" -> Audio (parse_audio_stream json)
  | "subtitle" -> Subtitle (parse_subtitle_stream json)
  | _ -> Data (parse_data_stream json)

(* ===================== *)
(* Main                  *)
(* ===================== *)

let capture_output_args prog args =
  let argv = Array.of_list (prog :: args) in
  let env = Unix.environment () in
  let stdout, stdin, stderr = Unix.open_process_args_full prog argv env in
  let out_buf = Buffer.create 4096 in
  let err_buf = Buffer.create 4096 in

  let rec read_channel ch buf =
    try
      let line = input_line ch in
      Buffer.add_string buf (line ^ "\n");
      read_channel ch buf
    with End_of_file -> ()
  in

  read_channel stdout out_buf;
  read_channel stderr err_buf;

  let status = Unix.close_process_full (stdout, stdin, stderr) in
  match status with
  | WEXITED 0 -> Ok (Buffer.contents out_buf)
  | _ ->
      let err_msg = String.trim (Buffer.contents err_buf) in
      Error (if err_msg = "" then "ffprobe exited with error" else err_msg)

let probe_file filepath =
  let ffprobe_path = "/opt/homebrew/bin/ffprobe" in
  let args =
    [
      "-v";
      "quiet";
      "-print_format";
      "json";
      "-show_streams";
      "-show_format";
      filepath;
    ]
  in

  match capture_output_args ffprobe_path args with
  | Error e -> Error e
  | Ok json_str -> (
      try
        let json = Yojson.Basic.from_string json_str in
        let streams =
          match member "streams" json with
          | `List streams -> List.map parse_stream streams
          | _ -> []
        in
        let format =
          match member "format" json with
          | `Assoc fmt_json -> parse_format (`Assoc fmt_json)
          | _ -> { filename = filepath; size = None }
        in
        Ok { streams; format }
      with
      | Yojson.Json_error msg -> Error ("JSON parse failed: " ^ msg)
      | e -> Error ("Unexpected error: " ^ Printexc.to_string e))
