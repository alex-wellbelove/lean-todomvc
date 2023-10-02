import Lake
open Lake DSL

require LeanServer from ".."/"lean_server"

package «lean_todomvc» {
  -- add package configuration options here
}

lean_lib «LeanTodomvc» {
  -- add library configuration options here
}

@[default_target]
lean_exe «lean_todomvc» {
  root := `Main
}
