open Smtp_unix

let () = match
    (sendmail
       ~port:"2525"
       ~name:"localhost"
       ~from:Addr.(of_string "test@example.org")
       ~to_:[Addr.(of_string "test@example.org")]
       ~body:"Bleh" ()) with
      | `Ok (code, msg) -> Printf.printf "OK %d %s\n" code msg
      | `Failure (code, msg) -> Printf.eprintf "Failure %d %s\n" code msg
