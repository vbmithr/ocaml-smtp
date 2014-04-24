module type IO = sig

  (** Monadic interface *)

  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val fail : exn -> 'a t
  (** Channel like communication *)

  type ic
  type oc

  val open_connection : host:string -> service:string -> (ic * oc) t
  val shutdown_connection : ic -> unit t

  val read_line : ic -> string t
  val print_line : oc -> string -> unit t
end

module type S = sig
  type 'a monad

  type handle
  (** Type of a handle to a SMTP connection. *)

  type request =
    [
    | `Helo of string
    | `From of string
    | `To of string
    | `Data
    | `Msg_body of string
    | `Quit
    ]
  (** Type of a request. *)

  type response =
    [
    | `Ok of int * string
    | `Failure of int * string
    ]
  (** Type of a response. *)

  module Addr : sig
    type t
    val of_string : string -> t
    val to_string : t -> string
  end
  (** Module for handling email addresses. *)

  exception Negative_reply of int * string
  (** Exception raised when the remote SMTP server returns a negative
      reply. *)

  val connect : ?host:string -> ?port:string -> name:string -> unit -> handle monad
  (** [open ~host ~port] is a promise of a handle to an open
      connection to the SMTP server located at [host:port]. *)

  val close : handle -> unit monad
  (** [close h] closes [h], cleanly exiting the connection to the SMTP
      server if needed. *)

  val request : handle -> request -> response monad
  (** [request h req] sends [req] to the SMTP server handled by
      [h]. *)

  val send : handle -> from:Addr.t -> to_:Addr.t list -> body:string
    -> response monad
  (** [send h ~from ~to_ ~body] use the SMTP handled by [h] to send a
      mail of body [~body] from address [~from] to addresses
      [~to_]. *)

  val sendmail : ?host:string -> ?port:string -> name:string -> from:Addr.t
    -> to_:Addr.t list -> body:string -> unit -> response monad
  (** [sendmail ~host ~port ~from ~to_ ~body] sends the mail of body
      [~body] from address [~from] to addresses [~to] using the SMTP
      server at address [host:port]. *)
end

module Make (IO : IO) = struct

  type 'a monad = 'a IO.t

  type handle = { ic:IO.ic; oc:IO.oc; name:string }

  type request =
    [
    | `Helo of string
    | `From of string
    | `To of string
    | `Data
    | `Msg_body of string
    | `Quit
    ]
  (** Type of a request. *)

  type response =
    [
    | `Ok of int * string
    | `Failure of int * string
    ]
  (** Type of a response. *)

  module Addr = struct
    type t = string
    let of_string addr = addr (* TODO: Check validity! *)
    let to_string addr = addr
  end

  exception Negative_reply of int * string

  let ( >>= ) = IO.bind

  let response_of_string str =
    let len = String.length str in
    let code = int_of_string (String.sub str 0 3) in
    let msg = String.sub str 4 (len - 4) in
    if str.[0] <> '5' && str.[0] <> '4' then `Ok (code, msg)
    else `Failure (code, msg)

  let connect ?(host="") ?(port="smtp") ~name () =
    IO.open_connection ~host ~service:port
    >>= fun (ic, oc) -> IO.read_line ic
    >>= fun str -> match (response_of_string str) with
      | `Ok (_,_) -> IO.return { ic; oc; name }
      | `Failure (code, msg) -> IO.fail (Negative_reply (code, msg))

  let close h = IO.shutdown_connection h.ic

  let string_of_req = function
    | `Helo str  -> "HELO " ^ str
    | `From addr -> "MAIL FROM:" ^ addr
    | `To addr   -> "RCPT TO:" ^ addr
    | `Data      -> "DATA"
    | `Msg_body str  -> str ^ "\r\n."
    | `Quit      -> "QUIT"

  let request h req =
    IO.print_line h.oc (string_of_req req)
    >>= fun () -> IO.read_line h.ic
    >>= fun resp -> IO.return (response_of_string resp)

  (* Stop executing commands after the first has failed *)
  let rec transaction hdl = function
    | [] -> raise (Invalid_argument "empty list")
    | [c] -> request hdl c
    | h::t -> (request hdl h >>= function
      | `Ok (_,_) -> transaction hdl t
      | `Failure (code, msg) -> IO.fail (Negative_reply (code, msg)))

  let send h ~from ~to_ ~body =
    let cmds = [`Helo h.name; `From from] @
      (List.map (fun str -> `To str) to_) @
      [`Data; `Msg_body body] in
    transaction h cmds

  let finally f g =
    try
      f () >>= fun ret -> g () >>= fun () -> IO.return ret
    with exn -> g () >>= fun () -> IO.fail exn

  let sendmail ?(host="") ?(port="smtp") ~name ~from ~to_ ~body () =
    connect ~host ~port ~name () >>= fun h ->
    finally
      (fun () -> send h ~from ~to_ ~body)
      (fun () -> IO.shutdown_connection h.ic)
end
