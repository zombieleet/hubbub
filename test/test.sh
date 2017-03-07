source testify.bash
source ../todo.sh
source functions.sh

assert expect "$(addTodo)" "Incomplete requirement for adding todo" "Test for command line argument" "should pass"
assert expect "$(addTodo 'hello world')" "Incomplete requirement for adding todo" "Test for command line argument" "should pass"
assert expect "$(addTodo 'hello world')" "" "Test for command line arguments" "should fail"

#assert expect "$(addTodo 'hello world' 'new todo' '12/13/2007' '4:12pm')" "" "Test for adding todo"  "should pass"
assert expect "$(addTodo 'hello world' 'new todo' '12/13/2007' '4:12pm')" "" "Test for adding todo"  "should fail"


assert done


