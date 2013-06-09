module IO : Smtp.IO
	with type 'a t = 'a Lwt.t =
struct
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
    | h::t -> Lwt_io.open_connection ~buffer_size:4096 h.Lwt_unix.ai_addr

  let shutdown_connection = Lwt_io.close

  let read_line = Lwt_io.read_line
  let print_line oc str = Lwt_io.write oc (str ^ "\r\n")
end

module Smtp = Smtp.Make (IO)
(* module Smtp = Smtp.Make (IO with type 'a t = 'a Lwt.t) *)
(* module Smtp = Smtp.Make ( (IO : Smtp.IO with type 'a t = 'a Lwt.t) ) *)
include Smtp
