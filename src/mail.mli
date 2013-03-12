(** Class for compose and send mail thru a SMTP server. 
   For example :
   {[
let zz = new Mail.mail;;
zz#set_from "mail\@mydomain";;
zz#set_rcpt "mail\@yourdomain";;
zz#set_subject "important message";;
zz#set_server "smtp.mydomain";;
zz#send;;
]}
 *)

class mail :
  object
      (** [self#from] return the sender address *) 
    method from : string

    method helo : string
      (** [self#helo] return the string use with HELO command. Default is
       {e Ocaml Mailer}. *) 

      (** [self#msg] return the body of the mail. *)
    method msg : string

      (** [self#rcpt] return the recipient address. *) 
    method rcpt : string

      (** [self#subject] return the mail subject. *)
    method subject : string

      (** [self#send] send the mail thru [self#server] *)
    method send : unit

      (** [self#server] return the server use for sending the mail.*)
    method server : string
   
      (** [self#set_from mail] set the sender address. *)
    method set_from : string -> unit

    method set_helo : string -> unit
      (** [self#set_helo s] set the string use with HELO command. *)

      (** [self#set_msg s] set body of the mail. *)
    method set_msg : string -> unit

      (** [self#set_rcpt mail] set the recipient address. *)
    method set_rcpt : string -> unit

      (** [self#set_server s] set the server use to send mail. *)
    method set_server : string -> unit

      (** [self#set_subject s] set the mail subject. *)
    method set_subject : string -> unit
  end
