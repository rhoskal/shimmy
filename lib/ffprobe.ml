open Yojson.Basic.Util

(* ===================== *)
(* Types                 *)
(* ===================== *)

type dovi_info = {
  bl_compatibility_id : int option;
  bl_present : bool;
  el_present : bool;
  level : int option;
  profile : int;
  rpu_present : bool;
  version_major : int option;
  version_minor : int option;
}

type video_stream = {
  index : int;
  avg_frame_rate : string option;
  bit_depth : int option;
  bitrate : int option;
  codec_name : string;
  dovi : dovi_info option;
  height : int;
  language : string option;
  pix_fmt : string option;
  profile : string option;
  width : int;
}

type audio_stream = {
  index : int;
  bitrate : int option;
  channel_layout : float option;
  channels : int option;
  codec_name : string;
  is_atmos : bool option;
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
(* JSON Parsers          *)
(* ===================== *)

module Json = struct
  module Tags = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let bit_rate t =
      match t |> member "BPS" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s

    let language t = t |> member "language" |> to_string_option
    let title t = t |> member "title" |> to_string_option
  end

  module Stream = struct
    type t = Yojson.Basic.t
    type kind = Video | Audio | Subtitle | Data

    let of_json json = json

    let tags t : Tags.t option =
      match t |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
      | _ -> None

    let codec_type t = t |> member "codec_type" |> to_string

    let kind t =
      match codec_type t with
      | "video" -> Video
      | "audio" -> Audio
      | "subtitle" -> Subtitle
      | _ -> Data
  end

  module SideData = struct
    type t = Yojson.Basic.t

    let of_json json = json
    let side_data_type t = t |> member "side_data_type" |> to_string_option

    let bl_present t =
      match t |> member "bl_present_flag" |> to_int_option with
      | Some 1 -> true
      | _ -> false

    let dv_bl_compatibility_id t =
      t |> member "dv_bl_signal_compatibility_id" |> to_int_option

    let dv_level t = t |> member "dv_level" |> to_int_option
    let dv_profile t = t |> member "dv_profile" |> to_int_option
    let dv_version_major t = t |> member "dv_version_major" |> to_int_option
    let dv_version_minor t = t |> member "dv_version_minor" |> to_int_option

    let el_present t =
      match t |> member "el_present_flag" |> to_int_option with
      | Some 1 -> true
      | _ -> false

    let is_dovi t =
      match side_data_type t with
      | Some "DOVI configuration record" -> true
      | _ -> false

    let rpu_present t =
      match t |> member "rpu_present_flag" |> to_int_option with
      | Some 1 -> true
      | _ -> false
  end

  module Video = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags t : Tags.t option =
      match t |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
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
      | None -> (
          match tags t with None -> None | Some tags -> Tags.bit_rate tags)
      | Some _ as result -> result

    let codec_name t = t |> member "codec_name" |> to_string

    let dovi t =
      match t |> member "side_data_list" with
      | `List side_list ->
          side_list
          |> List.find_opt (fun sd ->
              let sd' = SideData.of_json sd in
              SideData.is_dovi sd')
          |> Option.map (fun sd ->
              let sd' = SideData.of_json sd in
              {
                bl_compatibility_id = SideData.dv_bl_compatibility_id sd';
                bl_present = SideData.bl_present sd';
                el_present = SideData.el_present sd';
                level = SideData.dv_level sd';
                profile = SideData.dv_profile sd' |> Option.value ~default:0;
                rpu_present = SideData.rpu_present sd';
                version_major = SideData.dv_version_major sd';
                version_minor = SideData.dv_version_minor sd';
              })
      | _ -> None

    let height t = t |> member "height" |> to_int
    let index t = t |> member "index" |> to_int

    let language t =
      match tags t with None -> None | Some tags -> Tags.language tags

    let pix_fmt t = t |> member "pix_fmt" |> to_string_option
    let profile t = t |> member "profile" |> to_string_option
    let width t = t |> member "width" |> to_int
  end

  module Audio = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags t : Tags.t option =
      match t |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
      | _ -> None

    let bit_rate t =
      let first_pick =
        match t |> member "bit_rate" |> to_string_option with
        | None -> None
        | Some s -> int_of_string_opt s
      in
      match first_pick with
      | None -> (
          match tags t with None -> None | Some tags -> Tags.bit_rate tags)
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
    let index t = t |> member "index" |> to_int

    let language t =
      match tags t with None -> None | Some tags -> Tags.language tags

    let profile t = t |> member "profile" |> to_string_option

    let is_atmos t =
      Option.map
        (fun p ->
          let re = Re.compile (Re.str "Atmos") in
          Re.execp re p)
        (profile t)

    let sample_rate t =
      match t |> member "sample_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s

    let title t =
      match tags t with None -> None | Some tags -> Tags.title tags
  end

  module Subtitle = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags t : Tags.t option =
      match t |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
      | _ -> None

    let codec_name t = t |> member "codec_name" |> to_string

    let hearing_impaired t =
      match
        t |> member "disposition" |> member "hearing_impaired" |> to_int
      with
      | 1 -> true
      | _ -> false

    let index t = t |> member "index" |> to_int

    let language t =
      match tags t with None -> None | Some tags -> Tags.language tags

    let title t =
      match tags t with None -> None | Some tags -> Tags.title tags
  end

  module Data = struct
    type t = Yojson.Basic.t

    let of_json json = json
    let codec_name t = t |> member "codec_name" |> to_string
    let index t = t |> member "index" |> to_int
  end

  module Format = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags t : Tags.t option =
      match t |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
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
  let video = Json.Video.of_json video_json in
  {
    avg_frame_rate = Json.Video.avg_frame_rate video;
    bit_depth = Json.Video.bit_depth video;
    bitrate = Json.Video.bit_rate video;
    codec_name = Json.Video.codec_name video;
    dovi = Json.Video.dovi video;
    height = Json.Video.height video;
    index = Json.Video.index video;
    language = Json.Video.language video;
    pix_fmt = Json.Video.pix_fmt video;
    profile = Json.Video.profile video;
    width = Json.Video.width video;
  }

let parse_audio_stream audio_json : audio_stream =
  let audio = Json.Audio.of_json audio_json in
  {
    bitrate = Json.Audio.bit_rate audio;
    channel_layout = Json.Audio.channel_layout audio;
    channels = Json.Audio.channels audio;
    codec_name = Json.Audio.codec_name audio;
    index = Json.Audio.index audio;
    is_atmos = Json.Audio.is_atmos audio;
    language = Json.Audio.language audio;
    profile = Json.Audio.profile audio;
    sample_rate = Json.Audio.sample_rate audio;
    title = Json.Audio.title audio;
  }

let parse_subtitle_stream subs_json : subtitle_stream =
  let subs = Json.Subtitle.of_json subs_json in
  {
    index = Json.Subtitle.index subs;
    codec_name = Json.Subtitle.codec_name subs;
    hearing_impaired = Json.Subtitle.hearing_impaired subs;
    language = Json.Subtitle.language subs;
    title = Json.Subtitle.title subs;
  }

let parse_data_stream data_json : data_stream =
  let data = Json.Data.of_json data_json in
  { index = Json.Data.index data; codec_name = Json.Data.codec_name data }

let parse_format_info format_json : format_info =
  let format = Json.Format.of_json format_json in
  {
    bitrate = Json.Format.bit_rate format;
    duration = Json.Format.duration format;
    filename = Json.Format.filename format;
    format_name = Json.Format.format_name format;
    size = Json.Format.size format;
  }

let parse_stream_by_type stream_json =
  let stream = Json.Stream.of_json stream_json in

  match Json.Stream.kind stream with
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
