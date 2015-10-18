module IO = struct
  type 'a t = 'a Lwt.t
  let return = Lwt.return
  let bind = Lwt.bind
  let ( >>= ) = Lwt.bind
  let fail = Lwt.fail

  type ic = Lwt_io.input_channel
  type oc = Lwt_io.output_channel

  let open_connection ~host ~service =
    Lwt_unix.getaddrinfo host service [] >>= function
    | [] -> fail (Failure ("IP resolution failed for " ^ host))
    | h::t -> Lwt_io.open_connection h.Lwt_unix.ai_addr

  let shutdown_connection = Lwt_io.close

  let read_line = Lwt_io.read_line
  let print_line oc str = Lwt_io.write oc (str ^ "\r\n")
end

module Smtp = Smtp.Make (IO)
include Smtp
