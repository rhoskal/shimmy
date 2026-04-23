open Yojson.Basic.Util

(* ===================== *)
(* Domain Types          *)
(* ===================== *)

module Tags = struct
  type t = {
    bitrate : int option;
    language : string option;
    title : string option;
  }
end

module Disposition = struct
  type t = {
    default_present : bool;
    forced_present : bool;
    hearing_impaired_present : bool;
  }
end

module Dovi = struct
  type t = {
    bl_compatibility_id : int option;
    bl_present : bool;
    el_present : bool;
    level : int option;
    profile : int;
    rpu_present : bool;
    version_major : int option;
    version_minor : int option;
  }
end

module Video = struct
  type t = {
    index : int;
    bit_depth : int option;
    bitrate : int option;
    codec_name : string;
    disposition : Disposition.t;
    dovi : Dovi.t option;
    frame_rate : string option;
    height : int;
    language : string option;
    pix_fmt : string option;
    profile : string option;
    width : int;
  }
end

module Audio = struct
  type t = {
    index : int;
    bitrate : int option;
    channel_layout : float option;
    channels : int option;
    codec_name : string;
    disposition : Disposition.t;
    language : string option;
    profile : string option;
    sample_rate : int option;
    title : string option;
  }
end

module Subtitle = struct
  type t = {
    index : int;
    codec_name : string;
    disposition : Disposition.t;
    language : string option;
    title : string option;
  }
end

module Format = struct
  type t = {
    bitrate : int option;
    duration : float option;
    filename : string;
    format_name : string option;
    size : int option;
  }
end

module Data = struct
  type t = { index : int; codec_name : string }
end

module Stream = struct
  type t =
    | VideoStream of Video.t
    | AudioStream of Audio.t
    | SubtitleStream of Subtitle.t
    | DataStream of Data.t
end

module Probe = struct
  type t = { streams : Stream.t list; format_info : Format.t }
end

(* ===================== *)
(* JSON Parsers          *)
(* ===================== *)

module TagsParser = struct
  let of_json json : Tags.t =
    let bit_rate =
      match json |> member "BPS" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s
    in
    {
      bitrate = bit_rate;
      language = json |> member "language" |> to_string_option;
      title = json |> member "title" |> to_string_option;
    }
end

module DispositionParser = struct
  let of_json json : Disposition.t =
    let bool_field name =
      match json |> member name |> to_int_option with
      | Some 1 -> true
      | _ -> false
    in
    {
      default_present = bool_field "default";
      forced_present = bool_field "forced";
      hearing_impaired_present = bool_field "hearing_impaired";
    }
end

module VideoParser = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags (t : t) : Tags.t option =
    match t |> member "tags" with
    | `Assoc _ as tags_json -> Some (TagsParser.of_json tags_json)
    | _ -> None

  (* Convenience accessors *)
  let avg_frame_rate t = t |> member "avg_frame_rate" |> to_string_option

  let bit_depth t =
    match t |> member "bits_per_raw_sample" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let bitrate t =
    let first_pick =
      match t |> member "bit_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s
    in
    match first_pick with
    | None -> ( match tags t with None -> None | Some tags -> tags.bitrate)
    | Some _ as result -> result

  let codec_name t = t |> member "codec_name" |> to_string

  let dovi t : Dovi.t option =
    match t |> member "side_data_list" with
    | `List side_list ->
        List.find_opt
          (fun sd ->
            match sd |> member "side_data_type" |> to_string_option with
            | Some "DOVI configuration record" -> true
            | _ -> false)
          side_list
        |> Option.map (fun sd ->
            let open Dovi in
            {
              bl_compatibility_id =
                sd |> member "dv_bl_signal_compatibility_id" |> to_int_option;
              bl_present =
                (match sd |> member "bl_present_flag" |> to_int_option with
                | Some 1 -> true
                | _ -> false);
              el_present =
                (match sd |> member "el_present_flag" |> to_int_option with
                | Some 1 -> true
                | _ -> false);
              level = sd |> member "dv_level" |> to_int_option;
              profile =
                sd |> member "dv_profile" |> to_int_option
                |> Option.value ~default:0;
              rpu_present =
                (match sd |> member "rpu_present_flag" |> to_int_option with
                | Some 1 -> true
                | _ -> false);
              version_major = sd |> member "dv_version_major" |> to_int_option;
              version_minor = sd |> member "dv_version_minor" |> to_int_option;
            })
    | _ -> None

  let disposition t : Disposition.t =
    t |> member "disposition" |> DispositionParser.of_json

  let height t = t |> member "height" |> to_int
  let index t = t |> member "index" |> to_int
  let language t = match tags t with None -> None | Some tags -> tags.language
  let pix_fmt t = t |> member "pix_fmt" |> to_string_option
  let profile t = t |> member "profile" |> to_string_option
  let width t = t |> member "width" |> to_int
end

module AudioParser = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags (t : t) : Tags.t option =
    match t |> member "tags" with
    | `Assoc _ as tags_json -> Some (TagsParser.of_json tags_json)
    | _ -> None

  (* Convenience accessors *)
  let bitrate t =
    let first_pick =
      match t |> member "bit_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s
    in
    match first_pick with
    | None -> ( match tags t with None -> None | Some tags -> tags.bitrate)
    | Some _ as result -> result

  let channel_layout t =
    match t |> member "channel_layout" |> to_string_option with
    | None -> None
    | Some s ->
        if String.starts_with ~prefix:"9.1" s then Some 9.1
        else if String.starts_with ~prefix:"7.1" s then Some 7.1
        else if String.starts_with ~prefix:"5.1" s then Some 5.1
        else if String.starts_with ~prefix:"3.0" s then Some 3.0
        else if String.starts_with ~prefix:"2.0" s then Some 2.0
        else None

  let channels t = t |> member "channels" |> to_int_option
  let codec_name t = t |> member "codec_name" |> to_string

  let disposition t : Disposition.t =
    t |> member "disposition" |> DispositionParser.of_json

  let index t = t |> member "index" |> to_int
  let language t = match tags t with None -> None | Some tags -> tags.language
  let profile t = t |> member "profile" |> to_string_option

  let sample_rate t =
    match t |> member "sample_rate" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let title t = match tags t with None -> None | Some tags -> tags.title
end

module SubtitleParser = struct
  type t = Yojson.Basic.t

  let of_json json = json

  let tags (t : t) : Tags.t option =
    match t |> member "tags" with
    | `Assoc _ as tags_json -> Some (TagsParser.of_json tags_json)
    | _ -> None

  (* Convenience accessors *)
  let codec_name t = t |> member "codec_name" |> to_string

  let disposition t : Disposition.t =
    t |> member "disposition" |> DispositionParser.of_json

  let index t = t |> member "index" |> to_int
  let language t = match tags t with None -> None | Some tags -> tags.language
  let title t = match tags t with None -> None | Some tags -> tags.title
end

module FormatParser = struct
  type t = Yojson.Basic.t

  let of_json json = json

  (* Convenience accessors *)
  let bitrate t =
    match t |> member "bit_rate" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s

  let duration t =
    match t |> member "duration" |> to_string_option with
    | None -> None
    | Some s -> float_of_string_opt s

  let filename t = t |> member "filename" |> to_string
  let format_name t = t |> member "format_name" |> to_string_option

  let size t =
    match t |> member "size" |> to_string_option with
    | None -> None
    | Some s -> int_of_string_opt s
end

module DataParser = struct
  type t = Yojson.Basic.t

  let of_json json = json

  (* Convenience accessors *)
  let codec_name t = t |> member "codec_name" |> to_string
  let index t = t |> member "index" |> to_int
end

module StreamParser = struct
  type t = Yojson.Basic.t

  let of_json json = json

  (* Convenience accessors *)
  let codec_type t = t |> member "codec_type" |> to_string
end

(* ===================== *)
(* Stream Parsing        *)
(* ===================== *)

let parse_video_stream json : Video.t =
  let stream = VideoParser.of_json json in
  {
    index = VideoParser.index stream;
    bit_depth = VideoParser.bit_depth stream;
    bitrate = VideoParser.bitrate stream;
    codec_name = VideoParser.codec_name stream;
    disposition = VideoParser.disposition stream;
    dovi = VideoParser.dovi stream;
    frame_rate = VideoParser.avg_frame_rate stream;
    height = VideoParser.height stream;
    language = VideoParser.language stream;
    pix_fmt = VideoParser.pix_fmt stream;
    profile = VideoParser.profile stream;
    width = VideoParser.width stream;
  }

let parse_audio_stream json : Audio.t =
  let stream = AudioParser.of_json json in
  {
    index = AudioParser.index stream;
    bitrate = AudioParser.bitrate stream;
    channel_layout = AudioParser.channel_layout stream;
    channels = AudioParser.channels stream;
    codec_name = AudioParser.codec_name stream;
    disposition = AudioParser.disposition stream;
    language = AudioParser.language stream;
    profile = AudioParser.profile stream;
    sample_rate = AudioParser.sample_rate stream;
    title = AudioParser.title stream;
  }

let parse_subtitle_stream json : Subtitle.t =
  let stream = SubtitleParser.of_json json in
  {
    index = SubtitleParser.index stream;
    codec_name = SubtitleParser.codec_name stream;
    disposition = SubtitleParser.disposition stream;
    language = SubtitleParser.language stream;
    title = SubtitleParser.title stream;
  }

let parse_format_info json : Format.t =
  let info = FormatParser.of_json json in
  {
    bitrate = FormatParser.bitrate info;
    duration = FormatParser.duration info;
    filename = FormatParser.filename info;
    format_name = FormatParser.format_name info;
    size = FormatParser.size info;
  }

let parse_data_stream json : Data.t =
  let stream = DataParser.of_json json in
  { index = DataParser.index stream; codec_name = DataParser.codec_name stream }

let parse_stream_by_type json : Stream.t =
  let stream = StreamParser.of_json json in
  match StreamParser.codec_type stream with
  | "video" -> VideoStream (parse_video_stream json)
  | "audio" -> AudioStream (parse_audio_stream json)
  | "subtitle" -> SubtitleStream (parse_subtitle_stream json)
  | _ -> DataStream (parse_data_stream json)

(* ===================== *)
(* Public API            *)
(* ===================== *)

let video_streams (probe : Probe.t) : Video.t list =
  probe.streams
  |> List.filter_map (function Stream.VideoStream v -> Some v | _ -> None)

let audio_streams (probe : Probe.t) : Audio.t list =
  probe.streams
  |> List.filter_map (function Stream.AudioStream a -> Some a | _ -> None)

let subtitle_streams (probe : Probe.t) : Subtitle.t list =
  probe.streams
  |> List.filter_map (function Stream.SubtitleStream s -> Some s | _ -> None)

(* ===================== *)
(* For Testing           *)
(* ===================== *)

module Testing = struct
  let parse_video_stream = parse_video_stream
  let parse_audio_stream = parse_audio_stream
  let parse_subtitle_stream = parse_subtitle_stream
  let parse_format_info = parse_format_info
  let parse_data_stream = parse_data_stream
  let parse_stream_by_type = parse_stream_by_type
end

(* ===================== *)
(* Main / Entry Point    *)
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
  (* ffprobe -v quiet -print_format json -show_streams -show_format inputFile *)
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
          | `List streams' -> List.map parse_stream_by_type streams'
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
        Ok ({ streams; format_info } : Probe.t)
      with
      | Yojson.Json_error msg -> Error ("JSON parse failed: " ^ msg)
      | e -> Error ("Unexpected error: " ^ Printexc.to_string e))
