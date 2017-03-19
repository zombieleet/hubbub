### Hubbub --> A Command line Todo Application

Usage: hubbub `[OPTIONS]` `[ARGUMENT_TO_OPTIONS](Most argument are not compulsory)`

Create todo list with the capability of deleting and marking completed
todo at a specific date

If no option is specified it enters into interactive mood ( which has not been fully implemented )

hubbub uses ~/.bash_todo/ as a place for saving the todos
Mandatory arguments to long options are mandatory for short options too.

```bash
-a, --add-todo, add_todo    add todo
-r, --read-todo, read_todo  if no argument is specified it reads all the todo 
    [ARGUMENTS]
	   all                  behaves the same way if no argument is specified
       completed            spits out all todo marked as completed
       notcompleted         spits out all todo that has not been completed
       when
            [ARGUMENT]
							requires date in this format
							[FORMAT]
							month:day:year
							"month day  year"
							month can either be in its short form or long form day should be a number

-d, --delete-todo, delete_todo         deletes todo
	[ARGUMENTS]
		date               			   date format is the same format as that of  when in (-r|--read-todo|read_todo)
		title               		   deletes a todo by title ( the todos full title )

-m, --mark-completed, mark_completed   marks todo as completed
	[ARGUMENTS]
		date               date format is the same format as that of  when in (-r|--read-todo|read_todo)
		title              marks a todo as completed if the full title of the todo is passed as an argument to title

-e, --export-todo, export_todo          exports the todo
	[ARGUMENTS]
		json               				exports the todo as json
		
-i, --interative, interactive           goes into interactive mood

-h, --help, help                        shows this usage/help message

  NOTE: Only non short/long option is supported in interactive mood
        The same arguments are supported in interactive mood
        When adding a todo in interactive mood do not quote it
```

***example***

```bash

$./hubbub.bash add_todo "buy microsofot from bill gates"
$./hubbub.bash -a "repair laptop fan"
$./hubbub.bash --add-todo "fix router"
$./hubbub.bash -a "download intermediate blender tutorial"

$./hubbub.bash read_todo all
1.	[         ]	repair laptop fan
2.	[         ]	download intermediate blender tutorial
3.	[         ]	fix router
4.	[         ]	buy microsofot from bill gates

$./hubbub.bash mark_completed title "fix router"
$./hubbub.bash read_todo completed

1.	[completed]	fix router

$./hubbub.bash --read-todo notcompleted

1.	[         ]	repair laptop fan
2.	[         ]	download intermediate blender tutorial
3.	[         ]	buy microsofot from bill gates

$./hubbub.bash delete_todo "fix router"

$./hubbub.bash -r all

1.	[         ]	repair laptop fan
2.	[         ]	download intermediate blender tutorial
3.	[         ]	buy microsofot from bill gates

$./hubbub.bash export_todo json

$ cat .btdsh.json
```
```json
{
"48c9dec5":[{
	"completed":false,
	"content":"repair laptop fan",
	"dateOfCreation":"March:19:2017"
	}],
"a4aa139b":[{
	"completed":false,
	"content":"download intermediate blender tutorial",
	"dateOfCreation":"March:19:2017"
	}],
"fe02a458":[{
	"completed":false,
	"content":"buy microsofot from bill gates",
	"dateOfCreation":"March:19:2017"
	}]
}
```

