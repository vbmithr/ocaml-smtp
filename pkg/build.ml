#!/usr/bin/env ocaml
#directory "pkg"
#use "topkg.ml"

let unix = Env.bool "unix"
let lwt = Env.bool "lwt"
let () =
  Pkg.describe "smtp" ~builder:`OCamlbuild [
    Pkg.lib "pkg/META";
    Pkg.lib ~exts:Exts.module_library "src/smtp";
    Pkg.lib ~cond:lwt ~exts:Exts.module_library "src/smtp_lwt";
    Pkg.lib ~cond:unix ~exts:Exts.module_library "src/smtp_unix";
    Pkg.bin ~cond:lwt ~auto:true ~dst:"smtp_test_lwt" "test/test_lwt";
    Pkg.bin ~cond:unix ~auto:true ~dst:"smtp_test_unix" "test/test_unix";
  ]
