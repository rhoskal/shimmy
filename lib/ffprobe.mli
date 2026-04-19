type stream_type =
  | Video
  | Audio
  | Subtitle
  | Data
      (** Kind of media stream as reported by ffprobe.

          This corresponds to the "codec_type" field in ffprobe JSON:
          - "video" -> Video
          - "audio" -> Audio
          - "subtitle" -> Subtitle
          - anything else (e.g. "data", "attachment") -> Data *)

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
(** Video stream metadata extracted from ffprobe.

    Fields correspond closely to entries under "streams" in ffprobe JSON.

    - [index]: Zero-based stream index within the container.
    - [avg_frame_rate]: Raw ffprobe string (e.g. "30000/1001"). Not normalized.
    - [bit_depth]: Bits per pixel component, if available (e.g. 8, 10).
    - [codec_name]: Codec identifier (e.g. "h264", "hevc").
    - [duration]: Stream duration in seconds.
    - [height], [width]: Frame dimensions in pixels.
    - [language]: ISO language code from tags (e.g. "eng").
    - [pix_fmt]: Pixel format (e.g. "yuv420p").
    - [profile]: Codec profile (e.g. "High"). *)

type audio_stream = {
  index : int;
  bitrate : int option;
  channels : int option;
  codec_name : string;
  duration : float option;
  language : string option;
  profile : string option;
  sample_rate : int option;
  title : string option;
}
(** Audio stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index.
    - [bitrate]: Bitrate in bits per second.
    - [channels]: Number of audio channels (e.g. 2, 6).
    - [codec_name]: Codec identifier (e.g. "aac", "opus").
    - [duration]: Duration in seconds.
    - [language]: ISO language code from tags.
    - [profile]: Codec profile (e.g. "LC").
    - [sample_rate]: Sampling rate in Hz (e.g. 44100).
    - [title]: Stream title from metadata tags. *)

type subtitle_stream = {
  index : int;
  codec_name : string;
  hearing_impaired : bool;
  language : string option;
  title : string option;
}
(** Subtitle stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index.
    - [codec_name]: Subtitle codec (e.g. "subrip", "ass").
    - [hearing_impaired]: True if marked as SDH/HI (hearing impaired), inferred
      from disposition flags when available.
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
  filename : string;
  format_name : string option;
  size : int option;
}
(** Container-level metadata extracted from ffprobe "format".

    - [filename]: Input filename as reported by ffprobe.
    - [format_name]: Container format (e.g. "matroska", "mp4"), possibly a
      comma-separated list.
    - [size]: File size in bytes. *)

type probe_result = { streams : stream list; format : format_info }
(** Result of probing a media file with ffprobe.

    Contains:
    - [streams]: All streams found in the file.
    - [format]: Container-level metadata. *)

val probe_file : string -> (probe_result, string) Result.t
(** Run ffprobe on the given file and parse a subset of its JSON output.

    Returns:
    - [Ok result] on success
    - [Error msg] if ffprobe fails or the output cannot be parsed

    The error message is intended for diagnostics and may include stderr output
    or parsing details. *)

val get_video_streams : probe_result -> video_stream list
(** Extract all video streams from a probe result. *)

val get_audio_streams : probe_result -> audio_stream list
(** Extract all audio streams from a probe result. *)

val get_subtitle_streams : probe_result -> subtitle_stream list
(** Extract all subtitle streams from a probe result. *)
