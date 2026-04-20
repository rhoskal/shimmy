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

module Json_tags : sig
  type t

  val of_json : Yojson.Basic.t -> t
  val bit_rate : t -> int option
  val language : t -> string option
  val title : t -> string option
end = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let bit_rate t =
    match t |> member "BPS" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let language t = t |> member "language" |> to_string_option
  let title t = t |> member "title" |> to_string_option
end

module Json_stream : sig
  type t
  type kind = Video | Audio | Subtitle | Data

  val of_json : Yojson.Basic.t -> t
  val codec_type : t -> string
  val kind : t -> kind
end = struct
  type t = Yojson.Basic.t
  type kind = Video | Audio | Subtitle | Data

  let of_json json = json

  let tags t : Json_tags.t option =
    match t |> member "tags" with
    | `Assoc _ as obj -> Some (Json_tags.of_json obj)
    | _ -> None

  let codec_type t = t |> member "codec_type" |> to_string

  let kind t =
    match codec_type t with
    | "video" -> Video
    | "audio" -> Audio
    | "subtitle" -> Subtitle
    | _ -> Data
end

module Json_video : sig
  type t

  val of_json : Yojson.Basic.t -> t
  val avg_frame_rate : t -> string option
  val bit_depth : t -> int option
  val bit_rate : t -> int option
  val codec_name : t -> string
  val height : t -> int
  val index : t -> int
  val language : t -> string option
  val pix_fmt : t -> string option
  val profile : t -> string option
  val width : t -> int
end = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags t : Json_tags.t option =
    match t |> member "tags" with
    | `Assoc _ as obj -> Some (Json_tags.of_json obj)
    | _ -> None

  let avg_frame_rate t = t |> member "avg_frame_rate" |> to_string_option

  let bit_depth t =
    match t |> member "bits_per_raw_sample" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let bit_rate t =
    let first_pick =
      match t |> member "bit_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s
    in
    match first_pick with
    | Some _ as result -> result
    | None -> (
        match tags t with None -> None | Some tags -> Json_tags.bit_rate tags)

  let codec_name t = t |> member "codec_name" |> to_string
  let height t = t |> member "height" |> to_int
  let index t = t |> member "index" |> to_int

  let language t =
    match tags t with None -> None | Some tags -> Json_tags.language tags

  let pix_fmt t = t |> member "pix_fmt" |> to_string_option
  let profile t = t |> member "profile" |> to_string_option
  let width t = t |> member "width" |> to_int
end

module Json_audio : sig
  type t

  val of_json : Yojson.Basic.t -> t
  val bit_rate : t -> int option
  val channels : t -> int option
  val codec_name : t -> string
  val index : t -> int
  val language : t -> string option
  val profile : t -> string option
  val sample_rate : t -> int option
  val title : t -> string option
end = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags t : Json_tags.t option =
    match t |> member "tags" with
    | `Assoc _ as obj -> Some (Json_tags.of_json obj)
    | _ -> None

  let bit_rate t =
    let first_pick =
      match t |> member "bit_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s
    in
    match first_pick with
    | Some _ as result -> result
    | None -> (
        match tags t with None -> None | Some tags -> Json_tags.bit_rate tags)

  let channels t = t |> member "channels" |> to_int_option
  let codec_name t = t |> member "codec_name" |> to_string
  let index t = t |> member "index" |> to_int

  let language t =
    match tags t with None -> None | Some tags -> Json_tags.language tags

  let profile t = t |> member "profile" |> to_string_option

  let sample_rate t =
    match t |> member "sample_rate" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let title t =
    match tags t with None -> None | Some tags -> Json_tags.title tags
end

module Json_subtitles : sig
  type t

  val of_json : Yojson.Basic.t -> t
  val codec_name : t -> string
  val hearing_impaired : t -> bool
  val index : t -> int
  val language : t -> string option
  val title : t -> string option
end = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags t : Json_tags.t option =
    match t |> member "tags" with
    | `Assoc _ as obj -> Some (Json_tags.of_json obj)
    | _ -> None

  let codec_name t = t |> member "codec_name" |> to_string

  let hearing_impaired t =
    match t |> member "disposition" |> member "hearing_impaired" |> to_int with
    | 1 -> true
    | _ -> false

  let index t = t |> member "index" |> to_int

  let language t =
    match tags t with None -> None | Some tags -> Json_tags.language tags

  let title t =
    match tags t with None -> None | Some tags -> Json_tags.title tags
end

module Json_data : sig
  type t

  val of_json : Yojson.Basic.t -> t
  val codec_name : t -> string
  val index : t -> int
end = struct
  type t = Yojson.Basic.t

  let of_json json = json
  let codec_name t = t |> member "codec_name" |> to_string
  let index t = t |> member "index" |> to_int
end

module Json_format : sig
  type t

  val of_json : Yojson.Basic.t -> t
  val bit_rate : t -> int option
  val duration : t -> float option
  val filename : t -> string
  val format_name : t -> string option
  val size : t -> int option
end = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags t : Json_tags.t option =
    match t |> member "tags" with
    | `Assoc _ as obj -> Some (Json_tags.of_json obj)
    | _ -> None

  let bit_rate t =
    match t |> member "bit_rate" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let duration t =
    match t |> member "duration" |> to_string_option with
    | None -> None
    | Some s -> ( try Some (float_of_string s) with _ -> None)

  let filename t = t |> member "filename" |> to_string
  let format_name t = t |> member "format_name" |> to_string_option

  let size t =
    match t |> member "size" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s
end

(* ===================== *)
(* Helpers               *)
(* ===================== *)

let video_streams result =
  List.filter_map (function Video v -> Some v | _ -> None) result.streams

let audio_streams result =
  List.filter_map (function Audio a -> Some a | _ -> None) result.streams

let subtitle_streams result =
  List.filter_map (function Subtitle s -> Some s | _ -> None) result.streams

(* ===================== *)
(* Parsers               *)
(* ===================== *)

let parse_video_stream video_json : video_stream =
  let video = Json_video.of_json video_json in
  {
    avg_frame_rate = Json_video.avg_frame_rate video;
    bit_depth = Json_video.bit_depth video;
    bitrate = Json_video.bit_rate video;
    codec_name = Json_video.codec_name video;
    height = Json_video.height video;
    index = Json_video.index video;
    language = Json_video.language video;
    pix_fmt = Json_video.pix_fmt video;
    profile = Json_video.profile video;
    width = Json_video.width video;
  }

let parse_audio_stream audio_json : audio_stream =
  let audio = Json_audio.of_json audio_json in
  {
    bitrate = Json_audio.bit_rate audio;
    channels = Json_audio.channels audio;
    codec_name = Json_audio.codec_name audio;
    index = Json_audio.index audio;
    language = Json_audio.language audio;
    profile = Json_audio.profile audio;
    sample_rate = Json_audio.sample_rate audio;
    title = Json_audio.title audio;
  }

let parse_subtitle_stream subs_json : subtitle_stream =
  let subs = Json_subtitles.of_json subs_json in
  {
    index = Json_subtitles.index subs;
    codec_name = Json_subtitles.codec_name subs;
    hearing_impaired = Json_subtitles.hearing_impaired subs;
    language = Json_subtitles.language subs;
    title = Json_subtitles.title subs;
  }

let parse_data_stream data_json : data_stream =
  let data = Json_data.of_json data_json in
  { index = Json_data.index data; codec_name = Json_data.codec_name data }

let parse_format_info format_json : format_info =
  let format = Json_format.of_json format_json in
  {
    bitrate = Json_format.bit_rate format;
    duration = Json_format.duration format;
    filename = Json_format.filename format;
    format_name = Json_format.format_name format;
    size = Json_format.size format;
  }

let parse_stream_by_type stream_json =
  let stream = Json_stream.of_json stream_json in

  match Json_stream.kind stream with
  | Video -> Video (parse_video_stream stream_json)
  | Audio -> Audio (parse_audio_stream stream_json)
  | Subtitle -> Subtitle (parse_subtitle_stream stream_json)
  | Data -> Data (parse_data_stream stream_json)

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
