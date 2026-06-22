open Alcotest
open Shimmy

let format_info_json =
  {|{
    "filename": "movie.mkv",
    "nb_streams": 48,
    "nb_programs": 0,
    "nb_stream_groups": 0,
    "format_name": "matroska,webm",
    "format_long_name": "Matroska / WebM",
    "start_time": "0.000000",
    "duration": "5941.952000",
    "size": "28536869623",
    "bit_rate": "38420868",
    "probe_score": 100,
    "tags": {
      "title": "Movie for the ages",
      "creation_time": "2026-01-13T22:08:16.000000Z",
      "ENCODER": "Lavf62.3.100"
    }
  }|}

let video_stream_json =
  {|{
    "index": 0,
    "avg_frame_rate": "24000/1001",
    "codec_name": "hevc",
    "profile": "Main 10",
    "height": 1608,
    "pix_fmt": "yuv420p10le",
    "color_space": "bt2020nc",
    "color_transfer": "smpte2084",
    "color_primaries": "bt2020",
    "width": 3840,
    "disposition": {
      "default": 1,
      "forced": 0,
      "hearing_impaired": 0
    },
    "tags": {
      "language": "eng",
      "BPS": "30661884"
    },
    "side_data_list": [{
      "side_data_type": "DOVI configuration record",
      "dv_version_major": 1,
      "dv_version_minor": 0,
      "dv_profile": 8,
      "dv_level": 6,
      "rpu_present_flag": 1,
      "el_present_flag": 0,
      "bl_present_flag": 1,
      "dv_bl_signal_compatibility_id": 1,
      "dv_md_compression": "none"
    }]
  }|}

let audio_stream_json =
  {|{
    "index": 1,
    "codec_name": "dts",
    "profile": "DTS-HD MA + DTS:X IMAX",
    "bits_per_raw_sample": "24",
    "sample_rate": "48000",
    "channels": 8,
    "channel_layout": "7.1",
    "disposition": {
      "default": 1,
      "forced": 0,
      "hearing_impaired": 0
    },
    "tags": {
      "language": "eng",
      "BPS": "30661884",
      "title": "DTS-X 7.1"
    }
  }|}

let subtitle_stream_json =
  {|{
    "index": 3,
    "codec_name": "subrip",
    "disposition": {
      "default": 1,
      "forced": 0,
      "hearing_impaired": 1
    },
    "tags": {
      "language": "eng",
      "title": "English SDH",
      "BPS": "44"
    }
  }|}

let pp_channel_layout fmt = function
  | Ffprobe.Audio.Mono -> Format.fprintf fmt "Mono"
  | Ffprobe.Audio.Stereo -> Format.fprintf fmt "Stereo"
  | Ffprobe.Audio.Surround_3_0 -> Format.fprintf fmt "3.0"
  | Ffprobe.Audio.Surround_5_1 -> Format.fprintf fmt "5.1"
  | Ffprobe.Audio.Surround_7_1 -> Format.fprintf fmt "7.1"
  | Ffprobe.Audio.Surround_9_1 -> Format.fprintf fmt "9.1"
  | Ffprobe.Audio.Unknown s -> Format.fprintf fmt "Unknown(%s)" s

let eq_channel_layout a b = a = b

let testable_channel_layout =
  Alcotest.testable pp_channel_layout eq_channel_layout

let check_channel_layout = Alcotest.option testable_channel_layout

let test_parse_format_info () =
  let json = Yojson.Basic.from_string format_info_json in
  let info = Ffprobe.Testing.parse_format_info json in

  check (option int) "bit_rate" (Some 38420868) info.bitrate;
  check (option (float 1e-6)) "duration" (Some 5941.952000) info.duration;
  check string "filename" "movie.mkv" info.filename;
  check (option string) "format_name" (Some "matroska,webm") info.format_name;
  check (option int) "size" (Some 28536869623) info.size

let test_parse_video_stream () =
  let json = Yojson.Basic.from_string video_stream_json in
  let stream = Ffprobe.Testing.parse_video_stream json in

  check int "index" 0 stream.index;
  check (option string) "avg_frame_rate" (Some "24000/1001") stream.frame_rate;
  check (option int) "bit_depth" None stream.bit_depth;
  check (option int) "bit_rate" (Some 30661884) stream.bitrate;
  check string "codec_name" "hevc" stream.codec_name;
  (match stream.dovi with
  | None -> fail "expected dovi"
  | Some dovi ->
      check (option int) "bl_compatibility_id" (Some 1) dovi.bl_compatibility_id;
      check bool "bl_present" true dovi.bl_present;
      check bool "el_present" false dovi.el_present;
      check (option int) "level" (Some 6) dovi.level;
      check int "profile" 8 dovi.profile;
      check bool "rpu_present" true dovi.rpu_present;
      check (option int) "version_major" (Some 1) dovi.version_major;
      check (option int) "version_minor" (Some 0) dovi.version_minor);
  check int "height" 1608 stream.height;
  check (option string) "language" (Some "eng") stream.language;
  check (option string) "pix_fmt" (Some "yuv420p10le") stream.pix_fmt;
  check (option string) "profile" (Some "Main 10") stream.profile;
  check int "width" 3840 stream.width

let test_parse_audio_stream () =
  let json = Yojson.Basic.from_string audio_stream_json in
  let stream = Ffprobe.Testing.parse_audio_stream json in

  check int "index" 1 stream.index;
  check (option int) "bit_rate" (Some 30661884) stream.bitrate;
  check check_channel_layout "channel_layout" (Some Ffprobe.Audio.Surround_7_1)
    stream.channel_layout;
  check (option int) "channels" (Some 8) stream.channels;
  check (option string) "language" (Some "eng") stream.language;
  check (option string) "profile" (Some "DTS-HD MA + DTS:X IMAX") stream.profile;
  check (option int) "sample_rate" (Some 48000) stream.sample_rate;
  check (option string) "title" (Some "DTS-X 7.1") stream.title

let test_parse_subtitle_stream () =
  let json = Yojson.Basic.from_string subtitle_stream_json in
  let stream = Ffprobe.Testing.parse_subtitle_stream json in

  check int "index" 3 stream.index;
  check string "codec_name" "subrip" stream.codec_name;
  check bool "hearing_impaired_present" true
    stream.disposition.hearing_impaired_present;
  check (option string) "language" (Some "eng") stream.language;
  check (option string) "title" (Some "English SDH") stream.title

let () =
  run "ffprobe"
    [
      ("format", [ test_case "format" `Quick test_parse_format_info ]);
      ("video", [ test_case "video" `Quick test_parse_video_stream ]);
      ("audio", [ test_case "audio" `Quick test_parse_audio_stream ]);
      ("subtitle", [ test_case "subtitle" `Quick test_parse_subtitle_stream ]);
    ]
