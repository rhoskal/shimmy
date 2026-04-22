open Yojson.Basic.Util

(* ===================== *)
(* Types                 *)
(* ===================== *)

type disposition_info = {
  disp_default_present : bool;
  disp_forced_present : bool;
  disp_hearing_impaired_present : bool;
}

type tags_info = {
  tag_bit_rate : int option;
  tag_language : string option;
  tag_title : string option;
}

type dovi_info = {
  dovi_bl_compatibility_id : int option;
  dovi_bl_present : bool;
  dovi_el_present : bool;
  dovi_level : int option;
  dovi_profile : int;
  dovi_rpu_present : bool;
  dovi_version_major : int option;
  dovi_version_minor : int option;
}

type video_stream = {
  vs_index : int;
  vs_avg_frame_rate : string option;
  vs_bit_depth : int option;
  vs_bitrate : int option;
  vs_codec_name : string;
  vs_disposition : disposition_info;
  vs_dovi : dovi_info option;
  vs_height : int;
  vs_language : string option;
  vs_pix_fmt : string option;
  vs_profile : string option;
  vs_width : int;
}

type audio_stream = {
  as_index : int;
  as_atmos_present : bool option;
  as_bitrate : int option;
  as_channel_layout : float option;
  as_channels : int option;
  as_codec_name : string;
  as_disposition : disposition_info;
  as_language : string option;
  as_profile : string option;
  as_sample_rate : int option;
  as_title : string option;
}

type subtitle_stream = {
  ss_index : int;
  ss_codec_name : string;
  ss_disposition : disposition_info;
  ss_language : string option;
  ss_title : string option;
}

type data_stream = { ds_index : int; ds_codec_name : string }

type stream =
  | Video of video_stream
  | Audio of audio_stream
  | Subtitle of subtitle_stream
  | Data of data_stream

type format_info = {
  fi_bitrate : int option;
  fi_duration : float option;
  fi_filename : string;
  fi_format_name : string option;
  fi_size : int option;
}

type probe_result = { pr_streams : stream list; pr_format_info : format_info }

(* ===================== *)
(* JSON Parsers          *)
(* ===================== *)

module Json = struct
  module Disposition : sig
    type t = disposition_info

    val of_json : Yojson.Basic.t -> t
    val default : t -> bool
    val forced : t -> bool
    val hearing_impaired : t -> bool
  end = struct
    type t = disposition_info

    let of_json json =
      let bool_field name =
        match json |> member name |> to_int_option with
        | Some 1 -> true
        | _ -> false
      in
      {
        disp_default_present = bool_field "default";
        disp_forced_present = bool_field "forced";
        disp_hearing_impaired_present = bool_field "hearing_impaired";
      }

    (* Convenience accessors *)
    let default info = info.disp_default_present
    let forced info = info.disp_forced_present
    let hearing_impaired info = info.disp_hearing_impaired_present
  end

  module SideData : sig
    type t

    val of_json : Yojson.Basic.t -> t
    val side_data_type : t -> string option
    val bl_present : t -> bool
    val dv_bl_compatibility_id : t -> int option
    val dv_level : t -> int option
    val dv_profile : t -> int option
    val dv_version_major : t -> int option
    val dv_version_minor : t -> int option
    val el_present : t -> bool
    val dovi_present : t -> bool
    val rpu_present : t -> bool
  end = struct
    type t = Yojson.Basic.t

    let of_json json = json

    (* Convenience accessors *)
    let side_data_type sd = sd |> member "side_data_type" |> to_string_option

    let bl_present sd =
      match sd |> member "bl_present_flag" |> to_int_option with
      | Some 1 -> true
      | _ -> false

    let dv_bl_compatibility_id sd =
      sd |> member "dv_bl_signal_compatibility_id" |> to_int_option

    let dv_level sd = sd |> member "dv_level" |> to_int_option
    let dv_profile sd = sd |> member "dv_profile" |> to_int_option
    let dv_version_major sd = sd |> member "dv_version_major" |> to_int_option
    let dv_version_minor sd = sd |> member "dv_version_minor" |> to_int_option

    let el_present sd =
      match sd |> member "el_present_flag" |> to_int_option with
      | Some 1 -> true
      | _ -> false

    let dovi_present sd =
      match side_data_type sd with
      | Some "DOVI configuration record" -> true
      | _ -> false

    let rpu_present sd =
      match sd |> member "rpu_present_flag" |> to_int_option with
      | Some 1 -> true
      | _ -> false
  end

  module Tags : sig
    type t = tags_info

    val of_json : Yojson.Basic.t -> t
    val bit_rate : t -> int option
    val language : t -> string option
    val title : t -> string option
  end = struct
    type t = tags_info

    let of_json json =
      let bit_rate =
        match json |> member "BPS" |> to_string_option with
        | None -> None
        | Some s -> int_of_string_opt s
      in
      {
        tag_bit_rate = bit_rate;
        tag_language = json |> member "language" |> to_string_option;
        tag_title = json |> member "title" |> to_string_option;
      }

    let bit_rate info = info.tag_bit_rate
    let language info = info.tag_language
    let title info = info.tag_title
  end

  module Video : sig
    type t

    val of_json : Yojson.Basic.t -> t
    val avg_frame_rate : t -> string option
    val bit_depth : t -> int option
    val bit_rate : t -> int option
    val codec_name : t -> string
    val disposition : t -> Disposition.t
    val dovi : t -> dovi_info option
    val height : t -> int
    val index : t -> int
    val language : t -> string option
    val pix_fmt : t -> string option
    val profile : t -> string option
    val width : t -> int
  end = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags (info : t) : Tags.t option =
      match info |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
      | _ -> None

    (* Convenience accessors *)
    let avg_frame_rate info =
      info |> member "avg_frame_rate" |> to_string_option

    let bit_depth info =
      match info |> member "bits_per_raw_sample" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s

    let bit_rate info =
      let first_pick =
        match info |> member "bit_rate" |> to_string_option with
        | None -> None
        | Some s -> int_of_string_opt s
      in
      match first_pick with
      | None -> (
          match tags info with None -> None | Some tags -> Tags.bit_rate tags)
      | Some _ as result -> result

    let codec_name info = info |> member "codec_name" |> to_string

    let disposition info =
      match info |> member "disposition" with
      | `Assoc _ as obj -> Disposition.of_json obj
      | _ -> Disposition.of_json (`Assoc [])

    let dovi info =
      match info |> member "side_data_list" with
      | `List side_list ->
          side_list
          |> List.find_opt (fun sd ->
              SideData.of_json sd |> SideData.dovi_present)
          |> Option.map (fun sd ->
              let sd' = SideData.of_json sd in
              {
                dovi_bl_compatibility_id = SideData.dv_bl_compatibility_id sd';
                dovi_bl_present = SideData.bl_present sd';
                dovi_el_present = SideData.el_present sd';
                dovi_level = SideData.dv_level sd';
                dovi_profile =
                  SideData.dv_profile sd' |> Option.value ~default:0;
                dovi_rpu_present = SideData.rpu_present sd';
                dovi_version_major = SideData.dv_version_major sd';
                dovi_version_minor = SideData.dv_version_minor sd';
              })
      | _ -> None

    let height info = info |> member "height" |> to_int
    let index info = info |> member "index" |> to_int

    let language info =
      match tags info with None -> None | Some i -> Tags.language i

    let pix_fmt info = info |> member "pix_fmt" |> to_string_option
    let profile info = info |> member "profile" |> to_string_option
    let width info = info |> member "width" |> to_int
  end

  module Audio : sig
    type t

    val of_json : Yojson.Basic.t -> t
    val atmos_present : t -> bool option
    val bit_rate : t -> int option
    val channel_layout : t -> float option
    val channels : t -> int option
    val codec_name : t -> string
    val disposition : t -> Disposition.t
    val index : t -> int
    val language : t -> string option
    val profile : t -> string option
    val sample_rate : t -> int option
    val title : t -> string option
  end = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags (info : t) : Tags.t option =
      match info |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
      | _ -> None

    (* Convenience accessors *)
    let bit_rate audio =
      let first_pick =
        match audio |> member "bit_rate" |> to_string_option with
        | None -> None
        | Some s -> int_of_string_opt s
      in
      match first_pick with
      | None -> (
          match tags audio with None -> None | Some tags -> Tags.bit_rate tags)
      | Some _ as result -> result

    let channel_layout audio =
      match audio |> member "channel_layout" |> to_string_option with
      | None -> None
      | Some s ->
          if String.starts_with ~prefix:"9.1" s then Some 9.1
          else if String.starts_with ~prefix:"7.1" s then Some 7.1
          else if String.starts_with ~prefix:"5.1" s then Some 5.1
          else if String.starts_with ~prefix:"3.0" s then Some 3.0
          else if String.starts_with ~prefix:"2.0" s then Some 2.0
          else None

    let channels audio = audio |> member "channels" |> to_int_option
    let codec_name audio = audio |> member "codec_name" |> to_string

    let disposition audio =
      match audio |> member "disposition" with
      | `Assoc _ as obj -> Disposition.of_json obj
      | _ -> Disposition.of_json (`Assoc [])

    let index audio = audio |> member "index" |> to_int

    let language audio =
      match tags audio with None -> None | Some tags -> Tags.language tags

    let profile audio = audio |> member "profile" |> to_string_option

    let atmos_present audio =
      Option.map
        (fun p ->
          let re = Re.compile (Re.str "Atmos") in
          Re.execp re p)
        (profile audio)

    let sample_rate audio =
      match audio |> member "sample_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s

    let title audio =
      match tags audio with None -> None | Some tags -> Tags.title tags
  end

  module Subtitle : sig
    type t

    val of_json : Yojson.Basic.t -> t
    val index : t -> int
    val codec_name : t -> string
    val disposition : t -> Disposition.t
    val language : t -> string option
    val title : t -> string option
  end = struct
    type t = Yojson.Basic.t

    let of_json json = json

    let tags (info : t) : Tags.t option =
      match info |> member "tags" with
      | `Assoc _ as obj -> Some (Tags.of_json obj)
      | _ -> None

    (* Convenience accessors *)
    let codec_name sub = sub |> member "codec_name" |> to_string

    let disposition sub =
      match sub |> member "disposition" with
      | `Assoc _ as obj -> Disposition.of_json obj
      | _ -> Disposition.of_json (`Assoc [])

    let index sub = sub |> member "index" |> to_int

    let language sub =
      match tags sub with None -> None | Some tags -> Tags.language tags

    let title sub =
      match tags sub with None -> None | Some tags -> Tags.title tags
  end

  module Data : sig
    type t

    val of_json : Yojson.Basic.t -> t
    val codec_name : t -> string
    val index : t -> int
  end = struct
    type t = Yojson.Basic.t

    let of_json json = json

    (* Convenience accessors *)
    let codec_name data = data |> member "codec_name" |> to_string
    let index data = data |> member "index" |> to_int
  end

  module Format : sig
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

    (* Convenience accessors *)
    let bit_rate fmt =
      match fmt |> member "bit_rate" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s

    let duration fmt =
      match fmt |> member "duration" |> to_string_option with
      | None -> None
      | Some s -> ( try Some (float_of_string s) with _ -> None)

    let filename fmt = fmt |> member "filename" |> to_string
    let format_name fmt = fmt |> member "format_name" |> to_string_option

    let size fmt =
      match fmt |> member "size" |> to_string_option with
      | None -> None
      | Some s -> int_of_string_opt s
  end

  module Stream : sig
    type t
    type stream_kind = Video | Audio | Subtitle | Data

    val of_json : Yojson.Basic.t -> t
    val codec_type : t -> string
    val kind : t -> stream_kind
  end = struct
    type t = Yojson.Basic.t
    type stream_kind = Video | Audio | Subtitle | Data

    let of_json json = json

    (* Convenience accessors *)
    let codec_type stream = stream |> member "codec_type" |> to_string

    let kind stream =
      match codec_type stream with
      | "video" -> Video
      | "audio" -> Audio
      | "subtitle" -> Subtitle
      | _ -> Data
  end
end

(* ===================== *)
(* Helpers               *)
(* ===================== *)

let video_streams result =
  List.filter_map (function Video v -> Some v | _ -> None) result.pr_streams

let audio_streams result =
  List.filter_map (function Audio a -> Some a | _ -> None) result.pr_streams

let subtitle_streams result =
  List.filter_map
    (function Subtitle s -> Some s | _ -> None)
    result.pr_streams

(* ===================== *)
(* Parsers               *)
(* ===================== *)

let parse_video_stream vs_json : video_stream =
  let v = Json.Video.of_json vs_json in
  {
    vs_index = Json.Video.index v;
    vs_avg_frame_rate = Json.Video.avg_frame_rate v;
    vs_bit_depth = Json.Video.bit_depth v;
    vs_bitrate = Json.Video.bit_rate v;
    vs_codec_name = Json.Video.codec_name v;
    vs_disposition = Json.Video.disposition v;
    vs_dovi = Json.Video.dovi v;
    vs_height = Json.Video.height v;
    vs_language = Json.Video.language v;
    vs_pix_fmt = Json.Video.pix_fmt v;
    vs_profile = Json.Video.profile v;
    vs_width = Json.Video.width v;
  }

let parse_audio_stream as_json : audio_stream =
  let a = Json.Audio.of_json as_json in
  {
    as_index = Json.Audio.index a;
    as_atmos_present = Json.Audio.atmos_present a;
    as_bitrate = Json.Audio.bit_rate a;
    as_channel_layout = Json.Audio.channel_layout a;
    as_channels = Json.Audio.channels a;
    as_codec_name = Json.Audio.codec_name a;
    as_disposition = Json.Audio.disposition a;
    as_language = Json.Audio.language a;
    as_profile = Json.Audio.profile a;
    as_sample_rate = Json.Audio.sample_rate a;
    as_title = Json.Audio.title a;
  }

let parse_subtitle_stream ss_json : subtitle_stream =
  let s = Json.Subtitle.of_json ss_json in
  {
    ss_index = Json.Subtitle.index s;
    ss_codec_name = Json.Subtitle.codec_name s;
    ss_disposition = Json.Subtitle.disposition s;
    ss_language = Json.Subtitle.language s;
    ss_title = Json.Subtitle.title s;
  }

let parse_data_stream ds_json : data_stream =
  let d = Json.Data.of_json ds_json in
  { ds_index = Json.Data.index d; ds_codec_name = Json.Data.codec_name d }

let parse_format_info fi_json : format_info =
  let f = Json.Format.of_json fi_json in
  {
    fi_bitrate = Json.Format.bit_rate f;
    fi_duration = Json.Format.duration f;
    fi_filename = Json.Format.filename f;
    fi_format_name = Json.Format.format_name f;
    fi_size = Json.Format.size f;
  }

let parse_stream_by_type stream_json =
  let s = Json.Stream.of_json stream_json in

  match Json.Stream.kind s with
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
                fi_bitrate = None;
                fi_duration = None;
                fi_filename = filepath;
                fi_format_name = None;
                fi_size = None;
              }
        in
        Ok { pr_streams = streams; pr_format_info = format_info }
      with
      | Yojson.Json_error msg -> Error ("JSON parse failed: " ^ msg)
      | e -> Error ("Unexpected error: " ^ Printexc.to_string e))

module For_testing = struct
  let parse_video_stream = parse_video_stream
  let parse_audio_stream = parse_audio_stream
  let parse_subtitle_stream = parse_subtitle_stream
  let parse_data_stream = parse_data_stream
  let parse_format_info = parse_format_info
  let parse_stream_by_type = parse_stream_by_type
end
