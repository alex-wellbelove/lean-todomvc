
import «LeanTodomvc»
import LeanServer
import LeanSqlite
import LeanSqlite.Rows
open Lean
open scoped ProofWidgets.Jsx

def wsScript : String :=     "const socket = new WebSocket('ws://localhost:8090');
    socket.addEventListener('close',()=>{
    location.reload()});"

def head :=  <head>
<title>"VanillaJS • TodoMVC"</title>
<link rel="stylesheet" href="https://todomvc.com/examples/vanillajs/node_modules/todomvc-common/base.css"> </link>
<link rel="stylesheet" href="https://todomvc.com/examples/vanillajs/node_modules/todomvc-app-css/index.css"> </link>
</head>

def header :=  <header class_="header">
  <h1>todo</h1>
  <form hx_post = "/todo" hx_swap="beforeend" hx_target=".todo-list">
    <input class_="new-todo" placeholder="What needs to be done?" autofocus="True" name="todo" />
  </form>
 </header>


def footer := 
 <footer class_="footer">
 <span class_="todo-count"></span>
 <ul class_="filters">
   <li>
   <a href="#/" class_="selected">All</a>
   </li>
   <li>
     <a href="#/active">Active</a>
   </li>
   <li>
     <a href="#/completed">Completed</a>
   </li>
   </ul>
   <button class_="clear-completed">Clear completed</button>
   </footer>
  
def indexPage (todos : ProofWidgets.Html) := 

 <html> 
  <script src="https://unpkg.com/htmx.org@1.9.5"> </script>
  <script>
    {.text <| wsScript}
  </script>
 {head}
 <body>
 {header}
 <section_ class_="todoapp">
 <section_ class_="main">
 <input id="toggle-all" class_="toggle-all" type="checkbox"> </input>
 <label for_="toggle-all">"Mark all as complete"</label>
   {todos}

 </section_>
  {footer}
 </section_>
 </body>

 </html>


def parseBody (s : String) : List String := s.splitOn "="


def toUL (lis : List ProofWidgets.Html) : ProofWidgets.Html :=
  ProofWidgets.Html.element "ul" #[("class","todo-list")] lis.toArray

structure Todo where
  id : Int
  description : String
instance : Rows.FromRow Todo where
  fromRow s i := do
     let id ←  Rows.FromRow.fromRow s i
     let description ←  Rows.FromRow.fromRow s (i+1)
     return Todo.mk id description
instance : ToString Todo where
  toString todo := s!"({todo.id}, {todo.description})"
  
def todoExample (b : Todo) :=
<li id = {"todo-" ++ toString b.id}>
 <div class_="view">
  <input class_="toggle" type="checkbox"> </input>
  <label> {.text <| b.description} </label>
<button class_="destroy" hx_delete={"/todo/" ++ toString b.id} hx_target = {"#todo-" ++ toString b.id} > x </button>
</div>
</li>

def handleTodoPost(r : Request) : IO Response := do
    IO.println "Handling todo post"
    let body ← match r.body with
     | (Option.some b) => pure (parseBody b)[1]!
     | none => throw (IO.userError "")
    let db ← Database.open_db "db.sqlite"
    let stmt := s!"INSERT INTO todos (description) VALUES (\'{body}\') RETURNING id;"
    IO.println stmt
    let stmt ←  Statement.prepare db stmt
    let rows : List Int  ←  Rows.getRows stmt
    let todo := (Todo.mk rows[0]! body)
    Database.close db
    return dbg_trace "{todo}";  Response.mk 200 "ok" (htmlToString (todoExample todo)) []

def todoIdParser : Parsec Int := do
  Parsec.pchar '/' *> pure ()
  Parsec.pstring "todo" *> pure ()
  Parsec.pchar '/' *> pure ()
  let chars ←  Parsec.many1 Lean.Parsec.digit
  pure $ String.toInt! chars.toList.asString
  
def deleteId  (id: Int) (r: Request) : IO Response :=  do
    IO.println "deleting id"
    let db ← Database.open_db "db.sqlite"
    Database.exec db s!"delete from todos where id = {id}"
    Database.close db
    pure $ Response.mk 200 "OK" "" [] -- HTMX expects a 200 in the wreckage

def main : IO Unit := do
  let db ← Database.open_db "db.sqlite"
  let stmt ←  Statement.prepare db "select id, description from todos;";
  let rows : List Todo ←  Rows.getRows stmt
  IO.println rows
  Database.close db
  rows.forM (fun x => IO.println x)


  let ip2 ←  rows.mapM (fun x => do 
    return todoExample x)
  let ip := indexPage (toUL ip2)


  runServer [get "/" ip,
             post "/todo" handleTodoPost,
             Route.mk HTTPMethod.DELETE todoIdParser deleteId
             ]



