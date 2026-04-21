let format_duration sec =
  let hours = int_of_float (floor (sec /. 3600.0)) in
  let mins = int_of_float (floor (mod_float sec 3600.0 /. 60.0)) in
  let secs = mod_float sec 60.0 in
  Printf.sprintf "%02d:%02d:%06.3f" hours mins secs

let print_section_header (title : string) : unit =
  Printf.printf "\n=== %s ===\n" title

let get_fps (frame_rate : string) : string option =
  match frame_rate with
  | "24000/1001" -> Some "24p"
  | "25" -> Some "25p"
  | "30000/1001" -> Some "30p"
  | "50" -> Some "50p"
  | "60000/1001" -> Some "60p"
  | _ -> None

let get_bit_depth (stream : Ffprobe.video_stream) : int =
  match stream.bit_depth with
  | None -> (
      match stream.pix_fmt with
      | Some "yuv420p" -> 8
      | Some "yuv420p10le" -> 10
      | Some "yuv422p12le" -> 12
      | Some "yuv444p16le" -> 16
      | _ -> 8)
  | Some bd -> bd

let print_video_stream (stream : Ffprobe.video_stream) : unit =
  Printf.printf "Stream #%d (%s)\n" stream.index
    (match stream.language with None -> "und" | Some lang -> lang);

  Printf.printf "  • Codec      : %s\n"
    (String.uppercase_ascii stream.codec_name);

  Printf.printf "  • Resolution : %dx%d\n" stream.width stream.height;

  (match stream.bitrate with
  | None -> ()
  | Some b ->
      Printf.printf "  • Bitrate    : %.0f kbps\n"
        (Float.ceil (float_of_int b /. 1000.0)));

  Printf.printf "  • BitDepth   : %d\n" (get_bit_depth stream);

  (match stream.profile with
  | None -> ()
  | Some p -> Printf.printf "  • Profile    : %s\n" p);

  match stream.avg_frame_rate with
  | None -> ()
  | Some frame_rate ->
      Printf.printf "  • FrameRate  : %s\n"
        (match get_fps frame_rate with None -> "UNKNOWN" | Some fps -> fps)

let print_audio_stream (stream : Ffprobe.audio_stream) : unit =
  Printf.printf "Stream #%d (%s)\n" stream.index
    (match stream.language with None -> "und" | Some lang -> lang);

  Printf.printf "  • Codec      : %s\n"
    (String.uppercase_ascii stream.codec_name);

  (match stream.profile with
  | None -> ()
  | Some p -> Printf.printf "  • Profile    : %s\n" p);

  (match stream.bitrate with
  | None -> ()
  | Some b ->
      Printf.printf "  • Bitrate    : %.0f kbps\n"
        (Float.ceil (float_of_int b /. 1000.0)));

  (match stream.channels with
  | None -> ()
  | Some c -> Printf.printf "  • Channels   : %d\n" c);

  (match stream.sample_rate with
  | None -> ()
  | Some r -> Printf.printf "  • SampleRate : %d Hz\n" r);

  match stream.title with
  | None -> ()
  | Some t -> Printf.printf "  • Title      : %s\n" t

let print_subtitle_stream (stream : Ffprobe.subtitle_stream) : unit =
  Printf.printf "Stream #%d (%s)\n" stream.index
    (match stream.language with None -> "und" | Some lang -> lang);

  Printf.printf "  • Codec      : %s\n"
    (match stream.codec_name with
    | "ass" -> "ASS"
    | "hdmv_pgs_subtitle" -> "PGS"
    | "subrip" -> "SRT"
    | "vobsub" -> "VOBSUB"
    | _ -> "UNKNOWN");

  (match stream.title with
  | None -> ()
  | Some t -> Printf.printf "  • Title      : %s\n" t);

  Printf.printf "  • SDH        : %b\n" stream.hearing_impaired

let print_format_info (fmt : Ffprobe.format_info) : unit =
  Printf.printf "  • Filename   : %s\n" (Filename.basename fmt.filename);

  (match fmt.duration with
  | None -> ()
  | Some d -> Printf.printf "  • Duration   : %s\n" (format_duration d));

  (match fmt.size with
  | None -> ()
  | Some bytes ->
      if bytes > 1_000_000_000 then
        Printf.printf "  • Size       : %.2f GB\n"
          (float_of_int bytes /. 1_000_000_000.0)
      else
        Printf.printf "  • Size       : %.2f MB\n"
          (float_of_int bytes /. 1_000_000.0));

  (match fmt.bitrate with
  | None -> ()
  | Some b ->
      Printf.printf "  • Bitrate    : %.0f kbps\n"
        (Float.ceil (float_of_int b /. 1000.0)));

  Printf.printf "  • Container  : %s\n"
    (match fmt.format_name with
    | Some "matroska,webm" -> "MKV"
    | Some "mp4" -> "MP4"
    | _ -> "UNKNOWN")

let print_probe_result (result : Ffprobe.probe_result) : unit =
  print_section_header "FORMAT";
  print_format_info result.format_info;

  let videos = Ffprobe.video_streams result in
  if List.length videos > 0 then begin
    print_section_header "VIDEO";
    List.iter print_video_stream videos
  end;

  let audios = Ffprobe.audio_streams result in
  if List.length audios > 0 then begin
    print_section_header "AUDIO";
    List.iter print_audio_stream audios
  end;

  let subs = Ffprobe.subtitle_streams result in
  if List.length subs > 0 then begin
    print_section_header "SUBTITLES";
    List.iter print_subtitle_stream subs
  end;
  Printf.printf "\n"

let print_stream_summary (result : Ffprobe.probe_result) : unit =
  Printf.printf "Video: %d stream(s)\n"
    (List.length (Ffprobe.video_streams result));
  Printf.printf "Audio: %d stream(s)\n"
    (List.length (Ffprobe.audio_streams result));
  Printf.printf "Subtitles: %d stream(s)\n"
    (List.length (Ffprobe.subtitle_streams result))
