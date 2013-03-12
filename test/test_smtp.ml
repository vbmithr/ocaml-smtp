let h = Smtp.connect "gandalf.local";;
let status = Smtp.helo h "Robert";;
Smtp.mail h "zz@local";;
Smtp.rcpt h "robert@local";;
Smtp.data h "bienvenue";;
Smtp.quit h;;
(* let status = Smtp.quit h;; *)
(* if status then  *)
(*   print_string "OK" *)
(* else *)
(*   print_string "NO" *)
(* ;; *)
