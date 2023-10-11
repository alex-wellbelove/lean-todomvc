import Lake
open Lake DSL

require LeanServer from ".."/"lean_server"

package «lean_todomvc» {
  -- add package configuration options here
  moreLinkArgs := #["-L/opt/homebrew/opt/sqlite/lib","-lsqlite3"]
}

lean_lib «LeanTodomvc» {
  -- add library configuration options here
}

@[default_target]
lean_exe «lean_todomvc» {
  root := `Main
}
