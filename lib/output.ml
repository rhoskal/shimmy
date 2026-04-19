let format_duration sec =
  let hours = int_of_float (floor (sec /. 3600.0)) in
  let mins = int_of_float (floor (mod_float sec 3600.0 /. 60.0)) in
  let secs = mod_float sec 60.0 in
  Printf.sprintf "%02d:%02d:%06.3f" hours mins secs

let print_section_header (title : string) : unit =
  Printf.printf "\n=== %s ===\n" title

let get_fps (frame_rate : string) : int option =
  match frame_rate with
  | "24000/1001" -> Some 24
  | "30000/1001" -> Some 30
  | "60000/1001" -> Some 60
  | "0/0" -> Some 0
  | _ -> None

let get_bit_depth (stream : Ffprobe.video_stream) : int =
  match stream.bit_depth with
  | Some bd -> bd
  | None -> (
      match stream.pix_fmt with
      | Some "yuv420p" -> 8
      | Some "yuv420p10le" -> 10
      | Some "yuv422p12le" -> 12
      | Some "yuv444p16le" -> 16
      | _ -> 8)

let print_video_stream (stream : Ffprobe.video_stream) : unit =
  Printf.printf "Stream #%d (%s)\n" stream.index
    (match stream.language with Some lang -> lang | None -> "und");
  Printf.printf "  • Codec      : %s\n"
    (String.uppercase_ascii stream.codec_name);
  Printf.printf "  • Resolution : %dx%d\n" stream.width stream.height;
  (match stream.avg_frame_rate with
  | Some r -> (
      match get_fps r with
      | Some fps -> Printf.printf "  • FrameRate  : %d\n" fps
      | None -> Printf.printf "  • FrameRate  : unknown\n")
  | None -> ());
  (match stream.duration with
  | Some d -> Printf.printf "  • Duration   : %s\n" (format_duration d)
  | None -> ());
  Printf.printf "  • BitDepth   : %d\n" (get_bit_depth stream);
  match stream.profile with
  | Some p -> Printf.printf "  • Profile    : %s\n" p
  | None -> ()

let print_audio_stream (stream : Ffprobe.audio_stream) : unit =
  Printf.printf "Stream #%d (%s)\n" stream.index
    (match stream.language with Some lang -> lang | None -> "und");
  Printf.printf "  • Codec      : %s\n"
    (String.uppercase_ascii stream.codec_name);
  (match stream.profile with
  | Some p -> Printf.printf "  • Profile    : %s\n" p
  | None -> ());
  (match stream.channels with
  | Some c -> Printf.printf "  • Channels   : %d\n" c
  | None -> ());
  (match stream.bitrate with
  | Some b -> Printf.printf "  • Bitrate    : %d kbps\n" (b / 1000)
  | None -> ());
  (match stream.sample_rate with
  | Some r -> Printf.printf "  • SampleRate : %d Hz\n" r
  | None -> ());
  match stream.title with
  | Some t -> Printf.printf "  • Title      : %s\n" t
  | None -> ()

let print_subtitle_stream (stream : Ffprobe.subtitle_stream) : unit =
  Printf.printf "Stream #%d (%s)\n" stream.index
    (match stream.language with Some lang -> lang | None -> "und");
  Printf.printf "  • Codec      : %s\n"
    (match stream.codec_name with
    | "ass" -> "ASS"
    | "hdmv_pgs_subtitle" -> "PGS"
    | "subrip" -> "SRT"
    | "vobsub" -> "VOBSUB"
    | _ -> "UNKNOWN");
  (match stream.title with
  | Some t -> Printf.printf "  • Title      : %s\n" t
  | None -> ());
  Printf.printf "  • SDH        : %b\n" stream.hearing_impaired

let print_format_info (fmt : Ffprobe.format_info) : unit =
  Printf.printf "  • Name       : %s\n" (Filename.basename fmt.filename);
  (match fmt.size with
  | Some bytes ->
      if bytes > 1_073_741_824 then
        Printf.printf "  • Size       : %.2f GB\n"
          (float_of_int bytes /. 1_073_741_824.0)
      else
        Printf.printf "  • Size       : %.2f MB\n"
          (float_of_int bytes /. 1_048_576.0)
  | None -> ());
  Printf.printf "  • Container  : %s\n"
    (match fmt.format_name with
    | Some "matroska,webm" -> "MKV"
    | _ -> "unknown")

let print_probe_result (result : Ffprobe.probe_result) : unit =
  print_section_header "FILE";
  print_format_info result.format;

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
  end;
  Printf.printf "\n"

let print_stream_summary (result : Ffprobe.probe_result) : unit =
  Printf.printf "Video: %d stream(s)\n"
    (List.length (Ffprobe.get_video_streams result));
  Printf.printf "Audio: %d stream(s)\n"
    (List.length (Ffprobe.get_audio_streams result));
  Printf.printf "Subtitles: %d stream(s)\n"
    (List.length (Ffprobe.get_subtitle_streams result))
