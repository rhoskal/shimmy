(lang dune 3.22)

(name shimmy)

(version "0.3.0")

(generate_opam_files true)

(source
 (codeberg rhoskal/shimmy))

(homepage "https://codeberg.org/rhoskal/shimmy")

(bug_reports "https://codeberg.org/rhoskal/shimmy/issues")

(authors "Hans Hoffman (rhoskal)")

(maintainers "Hans Hoffman (rhoskal)")

(license Apache-2.0)

(package
 (name shimmy)
 (synopsis "A short synopsis")

 (depends
  ocaml
  dune
  (alcotest :with-test)
  cmdliner
  re
  yojson)

 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
