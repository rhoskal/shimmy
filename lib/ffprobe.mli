type stream_type = Video | Audio | Subtitle | Data  (** ? **)

type video_stream = {
  index : int;
  avg_frame_rate : string option;
  bit_depth : int option;
  codec_name : string;
  duration : float option;
  height : int;
  language : string option;
  pix_fmt : string option;
  profile : string option;
  width : int;
}
(** ? **)

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
(** ? **)

type subtitle_stream = {
  index : int;
  codec_name : string;
  hearing_impaired : bool;
  language : string option;
  title : string option;
}
(** ? **)

type data_stream = { index : int; codec_name : string }

type stream =
  | Video of video_stream
  | Audio of audio_stream
  | Subtitle of subtitle_stream
  | Data of data_stream  (** ? **)

type format_info = {
  filename : string;
  format_name : string option;
  size : int option;
}
(** ? **)

type probe_result = { streams : stream list; format : format_info }
(** ? **)

val probe_file : string -> (probe_result, string) Result.t
val get_video_streams : probe_result -> video_stream list
val get_audio_streams : probe_result -> audio_stream list
val get_subtitle_streams : probe_result -> subtitle_stream list
