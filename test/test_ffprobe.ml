open Alcotest

let test_x () = ()
let () = run "Ffprobe tests" [ ("???", [ test_case "x" `Quick test_x ]) ]
