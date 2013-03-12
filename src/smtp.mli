(** 
   Module implementing SMTP protocol for client side.
   For example :
   {[ 
try   
   let h = Smtp.connect host in
   Smtp.helo h myhost && Smtp.mail h mymail &&
   Smtp.rctp h hismail && Smtp.data h msg &&
   Smtp.quit h;
   Smtp.close h
with
| Smtp.Error s ->
   Printf.printf "smtp error : %s\n" s;
   exit 1
   ]}

*)


(** smtp server connection *)
type handle
      
      (** exception for the module *)
exception Error of int * string

    (** [connect host] return channels for 
       the connection with host on smtp port *)
val connect : string -> handle
    
    (** [close h] close the connection *) 
val close : handle -> unit
    
    (** [helo h hostname] send the HELO command thru the 
       handle h and with hostname as argument.
     Return exception [Error] if smtp server give an error code. *)
val helo : handle -> string -> bool
    
    (** [mail h mail] send a MAIL FROM command thru handle h and with
       mail as argument .
     Return exception [Error] if smtp server give an error code. *)
val mail : handle -> string -> bool 
    
    (** [rcpt h mail] send a RCPT TO command thru handle h and with
       mail as argument.
     Return exception [Error] if smtp server give an error code.  *)
val rcpt : handle -> string -> bool  
    
    (** [data h msg] send a DATA command and after the message msg.
     Return exception [Error] if smtp server give an error code.  *)
val data : handle -> string -> bool  
    
    (** [quit h] send a QUIT command thru handle h.
     Return exception [Error] if smtp server give an error code.  *)
val quit : handle -> bool
;;

