(*     OCaml library for sending mail *)
(*     Copyright (C) 2003 Robert Silve *)

(*     This program is free software; you can redistribute it and/or modify *)
(*     it under the terms of the GNU General Public License as published by *)
(*     the Free Software Foundation; either version 2 of the License, or *)
(*     (at your option) any later version. *)

(*     This program is distributed in the hope that it will be useful, *)
(*     but WITHOUT ANY WARRANTY; without even the implied warranty of *)
(*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the *)
(*     GNU General Public License for more details. *)

(*     You should have received a copy of the GNU General Public License *)
(*     along with this program; if not, write to the Free Software *)
(*     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA *)



exception Error of int*string;;

module type SMTP =
  sig
    type handle

    val connect : string -> handle
    val close : handle -> unit
    val helo : handle -> string -> bool
    val mail : handle -> string -> bool 
    val rcpt : handle -> string -> bool  
    val data : handle -> string -> bool  
    val send : handle -> unit 
    val soml : handle -> unit 
    val saml : handle -> unit 
    val rset : handle -> unit 
    val vrfy : handle -> unit 
    val expn : handle -> unit 
    val help : handle -> unit 
    val noop : handle -> unit 
    val quit : handle -> bool
    val turn : handle -> unit 
  end
;;


(* 

tools for resolving hostname or ip 

*)


let is_ip s =
  let re = Str.regexp "^\\([0-9][0-9]?[0-9]?\\)\\.\\([0-9][0-9]?[0-9]?\\)\\.\\([0-9][0-9]?[0-9]?\\)\\.\\([0-9][0-9]?[0-9]?\\)$"
  in
  if  Str.string_match re s 0 then
    let l = List.map (fun x -> Str.matched_group x s) [1;2;3;4]
    in
    let ll = List.map (fun x -> int_of_string x) l
    in
    let lll =  List.map (fun x -> (0 <= x && x < 255)) ll
    in
    List.fold_left (fun x y -> x && y) true lll
  else
    false
;;


let mk_sock_addr s =
  try
    let p = Unix.getservbyname "smtp" "tcp"
    in
    match is_ip s with
    | true -> 
	Unix.ADDR_INET (Unix.inet_addr_of_string s, p.Unix.s_port)
    | false -> 
	let h = Unix.gethostbyname s in
	Unix.ADDR_INET (h.Unix.h_addr_list.(0), p.Unix.s_port)
  with
  | exn -> raise exn
;;


(*

Module for reading SMTP answer

*)

module Answer =
  struct
    type t = { code : int; msg : string}

    let read ic =
      let re_code = Str.regexp "^[0-9][0-9][0-9]-\\(.*\\)$" and
	  re_fin  = Str.regexp "^\\([0-9][0-9][0-9]\\) \\(.*\\)$"
      in
      let rec get ic b =
	let s = input_line ic in
	match Str.string_match re_fin s 0 with
	| true -> 
	    let c = int_of_string (Str.matched_group 1 s) and
		m = Str.matched_group 2 s
	    in 
	    { code = c; msg = b^m }
	| _    ->
	    ignore(Str.string_match re_code s 0);
	    let m = Str.matched_group 1 s in
	    get ic (b^m)
      in
      get ic ""

  end
;;

(*

Module structure for SMTP 

*)



module SmtpStruct = 
  struct
    
    type handle =  {ic : in_channel; oc : out_channel}
	    

    let connect server =
      let (ic,oc) = Unix.open_connection (mk_sock_addr server)
      in
      let h = {ic=ic;oc=oc}
      in
      let a = Answer.read (h.ic)
      in
      match a.Answer.code with
      | 220 -> h
      | 421 -> raise (Error (a.Answer.code, a.Answer.msg))
      | _ -> raise (Error (0, "Unknow SMTP code"))

    let close h =
      close_in (h.ic);
      close_out (h.oc)



    let helo h s = 
      let oc = h.oc in
      output_string oc ("HELO "^s^"\013\010"); flush oc;
      let a = Answer.read (h.ic)
      in
      match a.Answer.code with
      | 250 -> true
      | 500 | 501 | 504 | 421 -> raise (Error (a.Answer.code, a.Answer.msg))
      | _   -> raise (Error (0,"Unknow SMTP code"))

    let mail h s = 
      let oc = h.oc in
      output_string oc ("MAIL FROM: "^s^"\013\010"); flush oc;
      let a = Answer.read (h.ic)
      in
      match a.Answer.code with
      | 250-> true
      | 552 | 451 | 452 | 500 | 501 | 421 -> raise (Error (a.Answer.code, a.Answer.msg))
      | _ -> raise (Error (0,"Unknow SMTP code"))

    let rcpt h s =  
      let oc = h.oc in
      output_string oc ("RCPT TO: "^s^"\013\010"); flush oc;
      let a = Answer.read (h.ic)
      in
      match a.Answer.code with
      | 250 | 251-> true
      | 550 | 551 | 552 | 553 | 450 | 451 | 452 
      | 500 | 501 | 503 | 421 -> raise (Error (a.Answer.code, a.Answer.msg))
      | _ -> raise (Error (0,"Unknow SMTP code"))

    let data h msg = 
      let oc = h.oc in
      output_string oc ("DATA\013\010"); flush oc;
      let a = Answer.read (h.ic)
      in
      match a.Answer.code with
      | 354 ->
	  begin
	    output_string oc (msg^"\013\010.\013\010"); flush oc;
	    let a = Answer.read (h.ic)
	    in
	    match a.Answer.code with
	    | 250 -> true
	    | 552 | 554 | 451 | 452 -> raise (Error (a.Answer.code ,a.Answer.msg))
	    | _ -> raise (Error (0,"Unknow SMTP code"))
	  end
      | 451 | 554 | 500 | 501 | 503 | 421 -> raise (Error (a.Answer.code, a.Answer.msg))
      | _ -> raise (Error (0,"Unknow SMTP code"))
            

      

    let send h = () 
    let soml h = () 
    let saml h = () 
    let rset h = () 
    let vrfy h = () 
    let expn h = () 
    let help h = () 
    let noop h = () 


    let quit h = 
      let oc = h.oc in
      output_string oc ("QUIT\013\010"); flush oc;
      let a = Answer.read (h.ic)
      in
      match a.Answer.code with
      | 221 -> true
      | 500 -> raise (Error (a.Answer.code, a.Answer.msg))
      | _ -> raise (Error (0,"Unknow SMTP code"))
	    
    let turn h = () 
	
	
  end;;

module My = (SmtpStruct : SMTP);;

type handle = My.handle;;

let connect = My.connect;;
let close = My.close;;
let helo = My.helo;;
let mail = My.mail;;
let rcpt = My.rcpt;;
let data = My.data;;
let quit = My.quit;;
