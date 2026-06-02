(* ===================== *)
(* Domain Types          *)
(* ===================== *)

(** Metadata tags extracted from streams or formats.

    - [bitrate]: Bitrate as reported in tags (may differ from main bitrate).
    - [language]: ISO 639 language code (e.g. "eng", "jpn").
    - [title]: Human-readable title or description for the stream. *)
module Tags : sig
  type t = private {
    bitrate : int option;
    language : string option;
    title : string option;
  }
end

(** Stream disposition flags.

    - [default_present]: True if the stream is marked as the default selection
      (e.g. the player should pick it automatically).
    - [forced_present]: True if the stream is marked as forced (e.g. subtitles
      that should always be shown regardless of user preference).
    - [hearing_impaired_present]: True if the stream is intended for
      hearing-impaired audiences (SDH/HI). *)
module Disposition : sig
  type t = private {
    default_present : bool;
    forced_present : bool;
    hearing_impaired_present : bool;
  }
end

(** Dolby Vision (DOVI) metadata extracted from video streams.

    - [bl_compatibility_id]: Base layer compatibility ID (if present).
    - [bl_present]: Whether a base layer is present.
    - [el_present]: Whether an enhancement layer is present.
    - [level]: DOVI level (e.g., 5, 8, 12).
    - [profile]: DOVI profile number.
    - [rpu_present]: Whether the RPU (Reference Picture Unit) is present.
    - [version_major]: Major version of the DOVI spec.
    - [version_minor]: Minor version of the DOVI spec. *)
module Dovi : sig
  type t = private {
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

(** Video stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index within the container.
    - [bit_depth]: Bits per pixel component, if available (e.g. 8, 10).
    - [bitrate]: Bitrate in bits per second.
    - [codec_name]: Codec identifier (e.g. "h264", "hevc").
    - [color_primaries]: Color primaries (e.g. "bt2020", "bt709").
    - [color_space]: Color space (e.g. "bt2020cll", "smpte2084").
    - [color_transfer]: Transfer characteristics / gamma curve (e.g. "smpte2084"
      for PQ, "bt709").
    - [disposition]: Disposition flags (see {!Disposition.t}).
    - [dovi]: Dolby Vision metadata if present (see {!Dovi.t}).
    - [frame_rate]: Raw ffprobe string (e.g. "30000/1001"). Not normalized.
    - [height], [width]: Frame dimensions in pixels.
    - [language]: ISO language code from tags (e.g. "eng").
    - [pix_fmt]: Pixel format (e.g. "yuv420p").
    - [profile]: Codec profile (e.g. "High"). *)
module Video : sig
  type t = private {
    index : int;
    bit_depth : int option;
    bitrate : int option;
    codec_name : string;
    color_primaries : string option;
    color_space : string option;
    color_transfer : string option;
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

(** Audio stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index.
    - [bitrate]: Bitrate in bits per second.
    - [channel_layout]: Output channel layout (e.g. 5.1).
    - [channels]: Number of audio channels (e.g. 2, 6).
    - [codec_name]: Codec identifier (e.g. "aac", "opus").
    - [disposition]: Disposition flags (see {!Disposition.t}).
    - [language]: ISO language code from tags.
    - [profile]: Codec profile (e.g. "LC").
    - [sample_rate]: Sampling rate in Hz (e.g. 44100).
    - [title]: Stream title from metadata tags. *)
module Audio : sig
  type channel_layout =
    | Mono
    | Stereo
    | Surround_3_0
    | Surround_5_1
    | Surround_7_1
    | Surround_9_1
    | Unknown of string

  type t = private {
    index : int;
    bitrate : int option;
    channel_layout : channel_layout option;
    channels : int option;
    codec_name : string;
    disposition : Disposition.t;
    language : string option;
    profile : string option;
    sample_rate : int option;
    title : string option;
  }
end

(** Subtitle stream metadata extracted from ffprobe.

    - [index]: Zero-based stream index.
    - [codec_name]: Codec identifier (e.g. "subrip", "ass").
    - [disposition]: Disposition flags (see {!Disposition.t}).
    - [language]: ISO language code from tags.
    - [title]: Stream title or description. *)
module Subtitle : sig
  type t = private {
    index : int;
    codec_name : string;
    disposition : Disposition.t;
    language : string option;
    title : string option;
  }
end

(** Container-level metadata extracted from ffprobe.

    - [bitrate]: Bitrate in bits per second.
    - [duration]: Stream duration in seconds.
    - [filename]: Input filename as reported by ffprobe.
    - [format_name]: Container format (e.g. "matroska,webm", "mp4"), possibly a
      comma-separated list.
    - [size]: File size in bytes. *)
module Format : sig
  type t = private {
    bitrate : int option;
    duration : float option;
    filename : string;
    format_name : string option;
    size : int option;
  }
end

(** Generic data stream (e.g. attachments, timed metadata).

    - [index]: Zero-based stream index.
    - [codec_name]: Codec identifier. *)
module Data : sig
  type t = private { index : int; codec_name : string }
end

module Stream : sig
  type t = private
    | VideoStream of Video.t
    | AudioStream of Audio.t
    | SubtitleStream of Subtitle.t
    | DataStream of Data.t
end

(** Container for the parsed media file metadata.

    - [streams]: A list of all detected streams (video, audio, subtitle, data).
    - [format_info]: Global metadata about the container format (see
      {!Format.t}). *)
module Probe : sig
  type t = private { streams : Stream.t list; format_info : Format.t }
end

(* ===================== *)
(* Public API            *)
(* ===================== *)

val video_streams : Probe.t -> Video.t list
(** Extract all video streams from a probe result.

    @param probe The result of [probe_media_file].
    @return A list of [Video.t]. *)

val audio_streams : Probe.t -> Audio.t list
(** Extract all audio streams from a probe result.

    @param probe The result of [probe_media_file].
    @return A list of [Audio.t]. *)

val subtitle_streams : Probe.t -> Subtitle.t list
(** Extract all subtitle streams from a probe result.

    @param probe The result of [probe_media_file].
    @return A list of [Subtitle.t]. *)

val probe_media_file : string -> (Probe.t, string) result
(** Probes a media file at [filepath] and returns its metadata.

    Runs [ffprobe] externally. Returns [Ok result] on success, or [Error msg] if
    the process fails or the JSON output is invalid. *)

(* ===================== *)
(* For Testing           *)
(* ===================== *)

(** Internal functions exposed for unit testing. *)
module Testing : sig
  val parse_video_stream : Yojson.Basic.t -> Video.t
  val parse_audio_stream : Yojson.Basic.t -> Audio.t
  val parse_subtitle_stream : Yojson.Basic.t -> Subtitle.t
  val parse_data_stream : Yojson.Basic.t -> Data.t
  val parse_format_info : Yojson.Basic.t -> Format.t
  val parse_stream_by_type : Yojson.Basic.t -> Stream.t
end
