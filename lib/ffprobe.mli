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
(** Dolby Vision configuration record metadata.

    Extracted from the "DOVI configuration record" entry inside a video stream's
    [side_data_list] in ffprobe output.

    - [profile]: Dolby Vision profile (e.g. 8 = Profile 8.1).
    - [level]: Dolby Vision level (e.g. 6).
    - [version_major] / [version_minor]: DOVI version (usually 1.0).
    - [bl_present], [el_present], [rpu_present]: Presence flags for Base Layer,
      Enhancement Layer, and Reference Processing Unit.
    - [bl_compatibility_id]: Backward compatibility signal (1 = HDR10, 2 = SDR,
      4 = HLG, etc.). *)

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
(** Video stream metadata extracted from ffprobe.

    Fields correspond closely to entries under "streams" in ffprobe JSON.

    - [index]: Zero-based stream index within the container.
    - [avg_frame_rate]: Raw ffprobe string (e.g. "30000/1001"). Not normalized.
    - [bit_depth]: Bits per pixel component, if available (e.g. 8, 10).
    - [bitrate]: Bitrate in bits per second.
    - [codec_name]: Codec identifier (e.g. "h264", "hevc").
    - [dovi]: Dolby Vision metadata if present (see {!dovi_info}).
    - [height], [width]: Frame dimensions in pixels.
    - [language]: ISO language code from tags (e.g. "eng").
    - [pix_fmt]: Pixel format (e.g. "yuv420p").
    - [profile]: Codec profile (e.g. "High"). *)

type audio_stream = {
  index : int;
  bitrate : int option;
  channel_layout : float option;
  channels : int option;
  codec_name : string;
  atmos_present : bool option;
  language : string option;
  profile : string option;
  sample_rate : int option;
  title : string option;
}
(** Audio stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index.
    - [bitrate]: Bitrate in bits per second.
    - [channel_layout]: Output channel layout (e.g. 5.1).
    - [channels]: Number of audio channels (e.g. 2, 6).
    - [codec_name]: Codec identifier (e.g. "aac", "opus").
    - [atmos_present]: True if the audio stream is Dolby Atmos.
    - [language]: ISO language code from tags.
    - [profile]: Codec profile (e.g. "LC").
    - [sample_rate]: Sampling rate in Hz (e.g. 44100).
    - [title]: Stream title from metadata tags. *)

type subtitle_stream = {
  index : int;
  codec_name : string;
  hearing_impaired_present : bool;
  language : string option;
  title : string option;
}
(** Subtitle stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index.
    - [codec_name]: Subtitle codec (e.g. "subrip", "ass").
    - [hearing_impaired_present]: True if marked as SDH/HI (hearing impaired),
      inferred from disposition flags when available.
    - [language]: ISO language code from tags.
    - [title]: Stream title or description. *)

type data_stream = { index : int; codec_name : string }
(** Generic data stream (e.g. attachments, timed metadata).

    These correspond to ffprobe streams with unhandled or non-media "codec_type"
    values. Only minimal metadata is exposed. *)

type stream =
  | Video of video_stream
  | Audio of audio_stream
  | Subtitle of subtitle_stream
  | Data of data_stream
      (** Unified representation of all stream types returned by ffprobe.

          Each constructor wraps a more specific record with fields relevant to
          that stream kind. *)

type format_info = {
  bitrate : int option;
  duration : float option;
  filename : string;
  format_name : string option;
  size : int option;
}
(** Container-level metadata extracted from ffprobe "format".

    - [bitrate]: Bitrate in bits per second.
    - [duration]: Stream duration in seconds.
    - [filename]: Input filename as reported by ffprobe.
    - [format_name]: Container format (e.g. "matroska", "mp4"), possibly a
      comma-separated list.
    - [size]: File size in bytes. *)

type probe_result = { streams : stream list; format_info : format_info }
(** Result of probing a media file with ffprobe.

    Contains:
    - [streams]: All streams found in the file.
    - [format_info]: Container-level metadata. *)

val probe_media_file : string -> (probe_result, string) Result.t
(** Run ffprobe on the given file and parse a subset of its JSON output.

    Returns:
    - [Ok result] on success
    - [Error msg] if ffprobe fails or the output cannot be parsed

    The error message is intended for diagnostics and may include stderr output
    or parsing details. *)

val video_streams : probe_result -> video_stream list
(** Extract all video streams from a probe result. *)

val audio_streams : probe_result -> audio_stream list
(** Extract all audio streams from a probe result. *)

val subtitle_streams : probe_result -> subtitle_stream list
(** Extract all subtitle streams from a probe result. *)

(**/**) (* This stops ocamldoc from including the rest in public docs *)

module For_testing : sig
  val parse_video_stream : Yojson.Basic.t -> video_stream
  val parse_audio_stream : Yojson.Basic.t -> audio_stream
  val parse_subtitle_stream : Yojson.Basic.t -> subtitle_stream
  val parse_data_stream : Yojson.Basic.t -> data_stream
  val parse_format_info : Yojson.Basic.t -> format_info
end

(**/**)
