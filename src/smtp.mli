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

module Make (IO : IO) : S with type 'a monad = 'a IO.t
