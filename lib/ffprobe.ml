open Yojson.Basic.Util

type video_stream = {
  index : int;
  avg_frame_rate : string option;
  bit_depth : int option;
  bitrate : int option;
  codec_name : string;
  height : int;
  language : string option;
  pix_fmt : string option;
  profile : string option;
  width : int;
}

type audio_stream = {
  index : int;
  bitrate : int option;
  channels : int option;
  codec_name : string;
  language : string option;
  profile : string option;
  sample_rate : int option;
  title : string option;
}

type subtitle_stream = {
  index : int;
  codec_name : string;
  hearing_impaired : bool;
  language : string option;
  title : string option;
}

type data_stream = { index : int; codec_name : string }

type stream =
  | Video of video_stream
  | Audio of audio_stream
  | Subtitle of subtitle_stream
  | Data of data_stream

type format_info = {
  bitrate : int option;
  duration : float option;
  filename : string;
  format_name : string option;
  size : int option;
}

type probe_result = { streams : stream list; format_info : format_info }

(* ===================== *)
(* Helpers               *)
(* ===================== *)

let video_streams result =
  List.filter_map (function Video v -> Some v | _ -> None) result.streams

let audio_streams result =
  List.filter_map (function Audio a -> Some a | _ -> None) result.streams

let subtitle_streams result =
  List.filter_map (function Subtitle s -> Some s | _ -> None) result.streams

let get_tags_duration tags_json =
  match member "tags" tags_json with
  | `Assoc tags -> (
      try
        match List.assoc_opt "BPS" tags with
        | Some (`String lang) -> int_of_string_opt lang
        | _ -> None
      with Not_found -> None)
  | _ -> None

let get_tags_language tags_json =
  match member "tags" tags_json with
  | `Assoc tags -> (
      try
        match List.assoc_opt "language" tags with
        | Some (`String lang) -> Some lang
        | _ -> None
      with Not_found -> None)
  | _ -> None

let get_tags_title tags_json =
  match member "tags" tags_json with
  | `Assoc tags -> (
      try
        match List.assoc_opt "title" tags with
        | Some (`String title) -> Some title
        | _ -> None
      with Not_found -> None)
  | _ -> None

(* ===================== *)
(* Parsers               *)
(* ===================== *)

let parse_video_stream video_json : video_stream =
  {
    index = video_json |> member "index" |> to_int;
    avg_frame_rate = video_json |> member "avg_frame_rate" |> to_string_option;
    bitrate = get_tags_duration video_json;
    bit_depth =
      video_json
      |> member "bits_per_raw_sample"
      |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
    codec_name = video_json |> member "codec_name" |> to_string;
    height = video_json |> member "height" |> to_int;
    language = get_tags_language video_json;
    pix_fmt = video_json |> member "pix_fmt" |> to_string_option;
    profile = video_json |> member "profile" |> to_string_option;
    width = video_json |> member "width" |> to_int;
  }

let parse_audio_stream audio_json : audio_stream =
  {
    index = audio_json |> member "index" |> to_int;
    bitrate =
      audio_json |> member "bit_rate" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
    channels = audio_json |> member "channels" |> to_int_option;
    codec_name = audio_json |> member "codec_name" |> to_string;
    language = get_tags_language audio_json;
    profile = audio_json |> member "profile" |> to_string_option;
    sample_rate =
      audio_json |> member "sample_rate" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
    title = get_tags_title audio_json;
  }

let parse_subtitle_stream subs_json : subtitle_stream =
  {
    index = subs_json |> member "index" |> to_int;
    codec_name = subs_json |> member "codec_name" |> to_string;
    hearing_impaired =
      ( subs_json |> member "disposition" |> member "hearing_impaired" |> to_int
      |> function
        | 1 -> true
        | _ -> false );
    language = get_tags_language subs_json;
    title = get_tags_title subs_json;
  }

let parse_data_stream data_json : data_stream =
  {
    index = data_json |> member "index" |> to_int;
    codec_name = data_json |> member "codec_name" |> to_string;
  }

let parse_format_info format_json =
  {
    bitrate =
      format_json |> member "bit_rate" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
    duration =
      format_json |> member "duration" |> to_string_option
      |> Option.map float_of_string;
    filename = format_json |> member "filename" |> to_string;
    format_name = format_json |> member "format_name" |> to_string_option;
    size =
      format_json |> member "size" |> to_string_option
      |> Option.map int_of_string_opt
      |> Option.join;
  }

let parse_stream_by_type stream_json =
  let codec_type_str =
    match member "codec_type" stream_json with `String s -> s | _ -> "UNKNOWN"
  in

  match codec_type_str with
  | "video" -> Video (parse_video_stream stream_json)
  | "audio" -> Audio (parse_audio_stream stream_json)
  | "subtitle" -> Subtitle (parse_subtitle_stream stream_json)
  | _ -> Data (parse_data_stream stream_json)

(* ===================== *)
(* Main                  *)
(* ===================== *)

let run_process_capture_output prog args =
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

let probe_media_file filepath =
  let ffprobe_path = Binaries.ffprobe_path () in
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

  match run_process_capture_output ffprobe_path args with
  | Error e -> Error e
  | Ok json_str -> (
      try
        let json = Yojson.Basic.from_string json_str in
        let streams =
          match member "streams" json with
          | `List streams -> List.map parse_stream_by_type streams
          | _ -> []
        in
        let format_info =
          match member "format" json with
          | `Assoc fmt_json -> parse_format_info (`Assoc fmt_json)
          | _ ->
              {
                bitrate = None;
                duration = None;
                filename = filepath;
                format_name = None;
                size = None;
              }
        in
        Ok { streams; format_info }
      with
      | Yojson.Json_error msg -> Error ("JSON parse failed: " ^ msg)
      | e -> Error ("Unexpected error: " ^ Printexc.to_string e))
