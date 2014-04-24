open Lwt
open Smtp_lwt

let main host port =
  Lwt_unix.handle_unix_error
    (fun () -> sendmail
        ~host
        ~port
        ~name:Unix.(gethostname ())
        ~from:Addr.(of_string "test@example.org")
        ~to_:[Addr.(of_string "test@example.org")]
        ~body:"Bleh" ()) ()
  >|= function
  | `Ok (code, msg) -> Printf.printf "OK %d %s\n" code msg
  | `Failure (code, msg) -> Printf.eprintf "Failure %d %s\n" code msg


let () =
  let args = ref [] in
  let speclist = Arg.(align []) in
  let anon_fun s = args := s::!args in
  let usage_msg = "Usage: " ^ Sys.argv.(0) ^ " [hostname (default \"localhost\")] [port (default \"smtp\")]\nOptions are:" in
  Arg.parse speclist anon_fun usage_msg;
  Lwt_main.run
    ((fun () -> match !args with
      | port::host::_ -> main host port
      | [host] -> main host "smtp"
      | [] -> main "localhost" "smtp") ())
