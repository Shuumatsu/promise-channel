type status = Closed | Open

(* I think bsb should also emit out two function `const Put = b -> [b]` and `const Take = 0`, but it does not *)
type 'b action = Put of 'b | Take

exception NotOpenChan

(* a receiver/sender may be registered on multi channels, but it should only receive/send once *)
type 'a promise = {mutable ok: bool; resolve: ('a -> unit[@bs])}

type 'a chan =
  { cap: int option
  ; buf: ('a * 'a promise) Queue.t
        (* in fact, transformer may also be a async function on JavaScript side*)
  ; transformer: 'a -> 'a
  ; receivers: 'a promise Queue.t
  ; mutable status: status }

let close chan = chan.status <- Closed

let cap {cap; _} = cap

let default_transformer x = x

let make ?cap ?(transformer = default_transformer) () =
  { cap
  ; buf= Queue.create ()
  ; transformer
  ; receivers= Queue.create ()
  ; status= Open }

(* called when take/put happens *)
let rec slide ({buf; receivers; _} as chan) =
  if Queue.is_empty receivers || Queue.is_empty buf then ()
  else
    match (Queue.peek buf, Queue.peek receivers) with
    | (_, {ok= true; _}), _ ->
        Queue.pop buf ; slide chan
    | _, {ok= true} ->
        Queue.pop receivers ; slide chan
    | _ ->
        let item, sender = Queue.pop buf in
        let receiver = Queue.pop receivers in
        receiver.ok <- true ;
        sender.ok <- true ;
        (sender.resolve item [@bs]) ;
        (receiver.resolve item [@bs])

let check_statuses arr =
  Array.fold_left
    (fun status chan ->
      match chan.status with Open -> status | Closed -> Closed)
    Open arr

(* deliver an item to any channel that is ready or will be the first to be ready *)
let deliver arr item =
  Js.Promise.make (fun ~resolve ~reject ->
      let sender = {ok= false; resolve} in
      (* additional loop here to check all statuses, for simplicity *)
      match check_statuses arr with
      | Open ->
          for i = 0 to Array.length arr - 1 do
            let ({cap; buf; transformer; _} as chan) = arr.(i) in
            (* transformer may be an async function, so I have this promise chain here *)
            (* but in this way I ignore the value returned, any better solution? *)
            transformer item |> Js.Promise.resolve
            |> Js.Promise.then_ (fun transformed ->
                   ( match cap with
                   | Some c when c > Queue.length buf -> (
                       resolve transformed [@bs] )
                   | _ ->
                       () ) ;
                   Queue.push (transformed, sender) chan.buf ;
                   Js.Promise.resolve (slide chan)) ;
            ()
          done
      | Closed -> (
          reject NotOpenChan [@bs] ))

let put chan item = deliver [|chan|] item

let is_completed {buf; status; _} = status = Closed && Queue.length buf = 0

(* take on a closed chan will cause a deadlock *)
let take chan =
  Js.Promise.make (fun ~resolve ~reject ->
      Queue.push {resolve; ok= false} chan.receivers ;
      slide chan)

(* A receive operation on a closed channel can always proceed immediately,
 * yielding the element type's zero value after any previously sent values have been received. *)
let take_or chan default_item =
  if is_completed chan then Js.Promise.resolve default_item
  else
    Js.Promise.make (fun ~resolve ~reject ->
        Queue.push {resolve; ok= false} chan.receivers ;
        slide chan)

(* Receiving from a channel until it's closed is normally done using for range *)
(* let range f ?(condition = fun _ -> Js.Promise.resolve true) chan =
  let rec h completed chan =
    if completed then Js.Promise.resolve ()
    else
      take chan
      |> Js.Promise.then_ (fun item -> f item ; condition item)
      |> Js.Promise.then_ (fun continue ->
             if continue then h (is_completed chan) chan
             else Js.Promise.resolve ())
  in
  h (is_completed chan) chan *)

(* may be useful when implementing select, but not used now *)
let is_ready_to_put {receivers; buf; cap} =
  match cap with
  | Some c when c > Queue.length buf ->
      true
  | _ ->
      Queue.length receivers > 0

let is_ready_to_take {buf; _} = Queue.length buf > 0

let is_ready chan action =
  match action with
  | Put _ ->
      is_ready_to_put chan
  | Take ->
      is_ready_to_take chan

let oneof arr =
  Js.Promise.make (fun ~resolve ~reject ->
      let receiver = {resolve; ok= false} in
      for i = 0 to Array.length arr - 1 do
        let chan = arr.(i) in
        Queue.push receiver chan.receivers ;
        slide chan
      done)

let oneof_or arr default_item =
  let rec h i arr =
    if i >= Array.length arr then None
    else if is_ready_to_take arr.(i) then Some i
    else h (i + 1) arr
  in
  match h 0 arr with
  | None ->
      Js.Promise.resolve default_item
  | Some i ->
      take arr.(i)

(* how to implement golang's select statement based on functions? *)
(* --- *)
(* let select ?(default_action = fun _ -> Js.Promise.resolve ()) arr =
  Js.Promise.make (fun ~resolve ~reject ->
      let promise = {ok= false; resolve} in
      match check_statuses (Array.map (fun (chan, _, _) -> chan) arr) with
      | Open ->
          for i = 0 to Array.length arr - 1 do
            let ({cap; buf; transformer; _} as chan), action, f = arr.(i) in
            match action with
            | Take ->
                Queue.push promise chan.receivers ;
                slide chan
            | Put item ->
                transformer item |> Js.Promise.resolve
                |> Js.Promise.then_ (fun transformed ->
                       ( match cap with
                       | Some c when c > Queue.length buf -> (
                           resolve transformed [@bs] )
                       | _ ->
                           () ) ;
                       Queue.push (transformed, promise) chan.buf ;
                       Js.Promise.resolve (slide chan)) ;
                ()
          done
      | Closed -> (
          reject NotOpenChan [@bs] )) *)