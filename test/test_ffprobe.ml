open Alcotest
open Shimmy.Ffprobe.For_testing

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

let test_parse_format_info () =
  let fi_json = Yojson.Basic.from_string format_info_json in
  let fmt = parse_format_info fi_json in

  check (option int) "bitrate" (Some 38420868) fmt.fi_bitrate;
  check (option (float 1e-6)) "duration" (Some 5941.952000) fmt.fi_duration;
  check string "filename" "movie.mkv" fmt.fi_filename;
  check (option string) "format_name" (Some "matroska,webm") fmt.fi_format_name;
  check (option int) "size" (Some 28536869623) fmt.fi_size

let test_parse_video_stream () =
  let vs_json = Yojson.Basic.from_string video_stream_json in
  let v = parse_video_stream vs_json in

  check int "index" 0 v.vs_index;
  check (option string) "avg_frame_rate" (Some "24000/1001") v.vs_avg_frame_rate;
  check (option int) "bit_depth" None v.vs_bit_depth;
  check (option int) "bitrate" (Some 30661884) v.vs_bitrate;
  check string "codec_name" "hevc" v.vs_codec_name;
  (match v.vs_dovi with
  | None -> fail "expected dovi"
  | Some dovi ->
      check (option int) "bl_compatibility_id" (Some 1)
        dovi.dovi_bl_compatibility_id;
      check bool "bl_present" true dovi.dovi_bl_present;
      check bool "el_present" false dovi.dovi_el_present;
      check (option int) "level" (Some 6) dovi.dovi_level;
      check int "profile" 8 dovi.dovi_profile;
      check bool "rpu_present" true dovi.dovi_rpu_present;
      check (option int) "version_major" (Some 1) dovi.dovi_version_major;
      check (option int) "version_minor" (Some 0) dovi.dovi_version_minor);
  check int "height" 1608 v.vs_height;
  check (option string) "language" (Some "eng") v.vs_language;
  check (option string) "pix_fmt" (Some "yuv420p10le") v.vs_pix_fmt;
  check (option string) "profile" (Some "Main 10") v.vs_profile;
  check int "width" 3840 v.vs_width

let test_parse_audio_stream () =
  let as_json = Yojson.Basic.from_string audio_stream_json in
  let a = parse_audio_stream as_json in

  check int "index" 1 a.as_index;
  check (option int) "bitrate" (Some 30661884) a.as_bitrate;
  check (option (float 1e-6)) "channel_layout" (Some 7.1) a.as_channel_layout;
  check (option int) "channels" (Some 8) a.as_channels;
  check (option bool) "atmos_present" (Some false) a.as_atmos_present;
  check (option string) "language" (Some "eng") a.as_language;
  check (option string) "profile" (Some "DTS-HD MA + DTS:X IMAX") a.as_profile;
  check (option int) "sample_rate" (Some 48000) a.as_sample_rate;
  check (option string) "title" (Some "DTS-X 7.1") a.as_title

let test_parse_subtitle_stream () =
  let ss_json = Yojson.Basic.from_string subtitle_stream_json in
  let s = parse_subtitle_stream ss_json in

  check int "index" 3 s.ss_index;
  check string "codec_name" "subrip" s.ss_codec_name;
  check bool "hearing_impaired_present" true
    s.ss_disposition.disp_hearing_impaired_present;
  check (option string) "language" (Some "eng") s.ss_language;
  check (option string) "title" (Some "English SDH") s.ss_title

let () =
  run "ffprobe"
    [
      ("format", [ test_case "format" `Quick test_parse_format_info ]);
      ("video", [ test_case "video" `Quick test_parse_video_stream ]);
      ("audio", [ test_case "audio" `Quick test_parse_audio_stream ]);
      ("subtitle", [ test_case "subtitle" `Quick test_parse_subtitle_stream ]);
    ]
