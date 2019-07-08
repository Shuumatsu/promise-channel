exception NotOpenChan

type 'b action = Put of 'b | Take

type 'a chan

val make : ?cap:int -> ?transformer:('a -> 'a) -> unit -> 'a chan

val cap : 'a chan -> int option

val deliver: 'a chan array -> 'a -> 'a Js.Promise.t

val put : 'a chan -> 'a -> 'a Js.Promise.t

val take : 'a chan -> 'a Js.Promise.t

val take_or : 'a chan -> 'a -> 'a Js.Promise.t

(* val range :
     ('a -> 'c Js.Promise.t)
  -> ?condition:('a -> bool Js.Promise.t)
  -> 'a chan
  -> unit Js.Promise.t *)

val close : 'a chan -> unit

val is_completed : 'a chan -> bool

val oneof : 'a chan array -> 'a Js.Promise.t

val oneof_or : 'a chan array -> 'a -> 'a Js.Promise.t

(* not implemented yet
val select :
     ?default_action:(unit -> unit Js.Promise.t)
  -> ('a chan * 'b action * ('a -> unit Js.Promise.t)) array
  -> unit Js.Promise.t *)
