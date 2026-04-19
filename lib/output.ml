let format_duration sec =
  let hours = int_of_float (floor (sec /. 3600.0)) in
  let mins = int_of_float (floor (mod_float sec 3600.0 /. 60.0)) in
  let secs = mod_float sec 60.0 in
  Printf.sprintf "%02d:%02d:%06.3f" hours mins secs

let print_section_header (title : string) : unit =
  Printf.printf "\n=== %s ===\n" title

let print_video_stream (stream : Ffprobe.video_stream) : unit =
  Printf.printf "Stream #%d (lang: %s)\n" stream.index
    (match stream.language with Some l -> l | None -> "und");
  Printf.printf "  • Codec      : %s\n" stream.codec_name;
  Printf.printf "  • Resolution : %dx%d\n" stream.width stream.height;
  (match stream.avg_frame_rate with
  | Some r -> Printf.printf "  • FrameRate  : %s\n" r
  | None -> ());
  match stream.duration with
  | Some d -> Printf.printf "  • Duration   : %s\n" (format_duration d)
  | None -> ()

let print_audio_stream (stream : Ffprobe.audio_stream) : unit =
  Printf.printf "Stream #%d (lang: %s)\n" stream.index
    (match stream.language with Some l -> l | None -> "und");
  Printf.printf "  • Codec      : %s\n" stream.codec_name;
  (match stream.profile with
  | Some p -> Printf.printf "  • Profile    : %s\n" p
  | None -> ());
  (match stream.sample_rate with
  | Some r -> Printf.printf "  • SampleRate : %d Hz\n" r
  | None -> ());
  (match stream.channels with
  | Some c -> Printf.printf "  • Channels   : %d\n" c
  | None -> ());
  (match stream.bitrate with
  | Some b -> Printf.printf "  • Bitrate    : %d kbps\n" (b / 1000)
  | None -> ());
  match stream.duration with
  | Some d -> Printf.printf "  • Duration   : %s\n" (format_duration d)
  | None -> ()

let print_subtitle_stream (stream : Ffprobe.subtitle_stream) : unit =
  Printf.printf "Stream #%d (lang: %s)\n" stream.index
    (match stream.language with Some l -> l | None -> "und");
  Printf.printf "  • Codec      : %s\n" stream.codec_name

let print_probe_result (result : Ffprobe.probe_result) : unit =
  let videos = Ffprobe.get_video_streams result in
  if List.length videos > 0 then begin
    print_section_header "VIDEO";
    List.iter print_video_stream videos
  end;

  let audios = Ffprobe.get_audio_streams result in
  if List.length audios > 0 then begin
    print_section_header "AUDIO";
    List.iter print_audio_stream audios
  end;

  let subs = Ffprobe.get_subtitle_streams result in
  if List.length subs > 0 then begin
    print_section_header "SUBTITLES";
    List.iter print_subtitle_stream subs
  end

let print_stream_summary (result : Ffprobe.probe_result) : unit =
  Printf.printf "=== shimmy summary ===\n";
  Printf.printf "Video: %d stream(s)\n"
    (List.length (Ffprobe.get_video_streams result));
  Printf.printf "Audio: %d stream(s)\n"
    (List.length (Ffprobe.get_audio_streams result));
  Printf.printf "Subtitles: %d stream(s)\n"
    (List.length (Ffprobe.get_subtitle_streams result))
