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


(* This a field header object.
    a field is : 
    field_name: field_body
*)

class 
  field  (name:string) =
  (* this part is intended to verify the field name *)
  let n = 
    let re = Str.regexp "^[^\000-\033\058\127]+$" in
    if (Str.string_match re name 0) then name
    else raise (Failure "incorrect header name")
  in
  object (self)
    val _name = n
    val mutable _body = ""
	
    method name = _name
    method body = _body
    method set_body s = 
      let re = Str.regexp 
	  "^[^\013\010]+\\(\013\010\\(\032\\|\009\\)[^\013\010]+\\)*$"
      in
      if (Str.string_match re s 0) then _body <- s
      else raise (Failure "incorrect header body")

    method to_string =
      Printf.sprintf "%s: %s" self#name self#body
  end
;;


(* this is an header object. 
   It's an agregation of field
*)


let header_type_fun f o=
  match o with
  | None -> f []
  | Some l -> f l
;;

class header =
  object (self)
    val mutable _headers = (None: field list option)
	
    method headers = 
      header_type_fun (fun x -> x) _headers
	
    method add_headers f = 
      _headers <- header_type_fun (fun x -> Some (f::x)) _headers
	
    method to_string =
      List.fold_left 
	(fun a b -> 
	  match a with 
	  | "" -> b#to_string
	  | _  -> a^"\n"^(b#to_string)) 
	"" self#headers
  end
;;


(* this is a mail object *)


let fun_option f o = 
  match o with
  | None -> "empty"
  | Some s -> f s
;;

let ident a = a ;; 

exception Error;;

class mail =
  object (self)
    val mutable _from = (None : string option)
    val mutable _to = (None : string option)
    val mutable _subject = (None : string option) 
    val mutable _server = (None : string option) 
    val mutable _msg = (None : string option)
    val mutable _helo = Some "Ocaml Mailer"

    method from = fun_option ident _from
    method rcpt = fun_option ident _to
    method subject = fun_option ident _subject
    method server = fun_option ident _server
    method msg = fun_option ident _msg
    method helo = fun_option ident _helo
	
    method set_from s = _from <- Some s
    method set_rcpt s = _to <- Some s
    method set_subject s = _subject <- Some s
    method set_server s = _server <- Some s
    method set_msg s = _msg <- Some s
    method set_helo s = _helo <- Some s

    method private header =
      let h = new header in
      List.iter 
	(fun x -> 
	  let n = new field (snd x) in
	  n#set_body (fst x);
	  h#add_headers n
	) 
	[(self#from, "From"); 
	 (self#rcpt, "To");
	 (self#subject, "Subject")];
      h
	

    method send =
      try
	let h = Smtp.connect self#server in
	let status =
	  Smtp.helo h self#helo &&
	  Smtp.mail h self#from &&
	  Smtp.rcpt h self#rcpt &&
	  Smtp.data h (Printf.sprintf 
			 "%s\013\010\013\010%s" 
			 self#header#to_string self#msg ) &&
	  Smtp.quit h 
	in
	if status then Smtp.close h else raise Error
      with
      | Smtp.Error (i,s) -> raise Error
		     
  end
;;


  
	  

