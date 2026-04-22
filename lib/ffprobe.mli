type disposition_info = {
  disp_default_present : bool;
  disp_forced_present : bool;
  disp_hearing_impaired_present : bool;
}
(** Stream disposition flags.

    - [disp_default_present]: True if the stream is marked as the default
      selection (e.g. the player should pick it automatically).
    - [disp_forced_present]: True if the stream is marked as forced (e.g.
      subtitles that should always be shown regardless of user preference).
    - [disp_hearing_impaired_present]: True if the stream is intended for
      hearing-impaired audiences (SDH/HI). *)

type tags_info = {
  tag_bit_rate : int option;
  tag_language : string option;
  tag_title : string option;
}
(** Common metadata tags extracted from a stream or format.

    - [tag_bit_rate]: Bitrate as reported in tags (may duplicate or differ from
      the main bitrate field).
    - [tag_language]: ISO 639 language code (e.g. "eng", "jpn").
    - [tag_title]: Human-readable title or description for the stream. *)

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
(** Dolby Vision configuration record metadata.

    - [dovi_profile]: Dolby Vision profile (e.g. 8 = Profile 8.1).
    - [dovi_level]: Dolby Vision level (e.g. 6).
    - [dovi_version_major] / [dovi_version_minor]: DOVI version (usually 1.0).
    - [dovi_bl_present], [dovi_el_present], [dovi_rpu_present]: Presence flags
      for Base Layer, Enhancement Layer, and Reference Processing Unit.
    - [dovi_bl_compatibility_id]: Backward compatibility signal (1 = HDR10, 2 =
      SDR, 4 = HLG, etc.). *)

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
(** Video stream metadata extracted from ffprobe.

    - [vs_index]: Zero-based stream index within the container.
    - [vs_avg_frame_rate]: Raw ffprobe string (e.g. "30000/1001"). Not
      normalized.
    - [vs_bit_depth]: Bits per pixel component, if available (e.g. 8, 10).
    - [vs_bitrate]: Bitrate in bits per second.
    - [vs_codec_name]: Codec identifier (e.g. "h264", "hevc").
    - [vs_disposition]: Disposition flags (see {!disposition_info}).
    - [vs_dovi]: Dolby Vision metadata if present (see {!dovi_info}).
    - [vs_height], [vs_width]: Frame dimensions in pixels.
    - [vs_language]: ISO language code from tags (e.g. "eng").
    - [vs_pix_fmt]: Pixel format (e.g. "yuv420p").
    - [vs_profile]: Codec profile (e.g. "High"). *)

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
(** Audio stream metadata extracted from ffprobe.

    - [as_index]: Zero-based stream index.
    - [as_atmos_present]: True if the audio stream is Dolby Atmos.
    - [as_bitrate]: Bitrate in bits per second.
    - [as_channel_layout]: Output channel layout (e.g. 5.1).
    - [as_channels]: Number of audio channels (e.g. 2, 6).
    - [as_codec_name]: Codec identifier (e.g. "aac", "opus").
    - [as_disposition]: Disposition flags (see {!disposition_info}).
    - [as_language]: ISO language code from tags.
    - [as_profile]: Codec profile (e.g. "LC").
    - [as_sample_rate]: Sampling rate in Hz (e.g. 44100).
    - [as_title]: Stream title from metadata tags. *)

type subtitle_stream = {
  ss_index : int;
  ss_codec_name : string;
  ss_disposition : disposition_info;
  ss_language : string option;
  ss_title : string option;
}
(** Subtitle stream metadata extracted from ffprobe.

    - [ss_index]: Zero-based stream index.
    - [ss_codec_name]: Subtitle codec (e.g. "subrip", "ass").
    - [ss_disposition]: Disposition flags (see {!disposition_info}).
    - [ss_language]: ISO language code from tags.
    - [ss_title]: Stream title or description. *)

type data_stream = { ds_index : int; ds_codec_name : string }
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
  fi_bitrate : int option;
  fi_duration : float option;
  fi_filename : string;
  fi_format_name : string option;
  fi_size : int option;
}
(** Container-level metadata extracted from ffprobe "format".

    - [fi_bitrate]: Bitrate in bits per second.
    - [fi_duration]: Stream duration in seconds.
    - [fi_filename]: Input filename as reported by ffprobe.
    - [fi_format_name]: Container format (e.g. "matroska", "mp4"), possibly a
      comma-separated list.
    - [fi_size]: File size in bytes. *)

type probe_result = { pr_streams : stream list; pr_format_info : format_info }
(** Result of probing a media file with ffprobe.

    Contains:
    - [pr_streams]: All streams found in the file.
    - [pr_format_info]: Container-level metadata. *)

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
