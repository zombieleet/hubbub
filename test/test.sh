source testify.bash
source ../todo.sh
source functions.sh
assert expect "$(addTodo)" "Incomplete requirement for adding todo" "Test for command line argument" "should pass"
assert expect "$(addTodo $1)" "" "add todo" "should pass"
assert expect "$(addTodo $1)" "$1 already exists, choose a new name" "if file already exists" "should pass"
assert done


