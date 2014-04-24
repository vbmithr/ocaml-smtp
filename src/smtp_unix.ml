module IO = struct
  type 'a t = 'a
  let return v = v
  let bind v f = f v
  let fail exn = raise exn

  type ic = in_channel
  type oc = out_channel

  let open_connection ~host ~service =
    match Unix.getaddrinfo host service [] with
      | [] -> fail (Failure ("IP resolution failed for " ^ host))
      | h::t -> Unix.open_connection h.Unix.ai_addr

  let shutdown_connection = Unix.shutdown_connection

  let read_line = input_line
  let print_line oc str = output_string oc (str ^ "\r\n"); flush oc
end

module Smtp = Smtp.Make (IO)
include Smtp
