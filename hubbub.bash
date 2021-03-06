#!/usr/bin/env bash

#
#  Nick [zombieleet|73mp74710n]
#  Email [<zombieleetnca@gmail.com>]
#  Name [Victory Osikwemhe]
#
#
#[LICENSE]
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

_isCommand=$(type -t sha256deep);

[[ $_isCommand != 'file' ]] && {
    printf "%s\n" "sha256deep command was not found on this system"
    exit 1;
}
. functions.sh

readonly TODO_DIR="${HOME}/.bash_todo/"
declare -a _HOLD_FILE_NAME

license() {
    cat <<'EOF'
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

EOF
}

header() {

    cat <<'EOF'
 _           _     _           _     
| |__  _   _| |__ | |__  _   _| |__  
| '_ \| | | | '_ \| '_ \| | | | '_ \ 
| | | | |_| | |_) | |_) | |_| | |_) |
|_| |_|\__,_|_.__/|_.__/ \__,_|_.__/ 

              COMMAND LINE TODO APPLICATION



EOF
    sleep 0.10
}

usage() {
    cat <<'EOF'
Usage: hubbub [OPTIONS] [ARGUMENT_TO_OPTIONS](Most argument are not compulsory)
Create todo list with the capability of deleting and marking completed
todo at a specific date

If no option is specified it enters into interactive mood ( which has not been fully implemented )

hubbub uses ~/.bash_todo/ as a place for saving the todos
Mandatory arguments to long options are mandatory for short options too.

     -a, --add-todo, add_todo              add's todo
     -r, --read-todo, read_todo            if no argument is specified it reads all the todo 
                  [ARGUMENTS]
                       all                 behaves the same way if no argument is specified
                       completed           spits out all todo marked as completed
                       notcompleted        spits out all todo that has not been completed
                       when
                          [ARGUMENT]
                                           requires date in this format
                                           [FORMAT]
                                              month:day:year
                                              "month day  year"
                                           month can either be in it's short form or long form
                                           day should be a number

    -d, --delete-todo, delete_todo         deletes todo
                  [ARGUMENTS]
                        date               date format is the same format as that of  when in (-r|--read-todo|read_todo)
                        title              deletes a todo by title ( the todos full title )

    -m, --mark-completed, mark_completed   marks todo as completed
                  [ARGUMENTS]
                        date               date format is the same format as that of  when in (-r|--read-todo|read_todo)
                        title              marks a todo as completed if the full title of the todo is passed as an argument to title

   -e, --export-todo, export_todo          exports the todo
                  [ARGUMENTS]
                        json               exports the todo as json
   -i, --interative, interactive           goes into interactive mood
   -h, --help, help                        shows this usage/help message

  NOTE: Only non short/long option is supported in interactive mood
        The same arguments are supported in interactive mood
        When adding a todo in interactive mood do not quote it


REPORT BUG: https://github.com/zombieleet/hubbub/issues
CONTRIBUTE: https://github.com/zombieleet/hubbub
EOF
}

init_todo() {
    tput reset
    header

    tput cup 5
    
    printf "\n\n\n"
    
    readTodo all
    tput cup ${LINENO}
    
    while read -ep": " line rest __rest;do

	tput reset
	tput cup 5
	
	case "${line}" in
	    'add_todo')
		__todoToAdd="${rest} ${__rest}"
		addTodo "${__todoToAdd}"
		sleep 1 && init_todo
		;;
	    'read_todo')
		header
		readTodo "${rest}" "${__rest}"
		;;    
	    'delete_todo')
		header
		deleteTodo "${rest}" "${__rest}"
		tput cup ${LINENO}
		;;
	    'mark_completed')
		header
		markCompleted "${rest}" "${__rest}"
		sleep 1 && init_todo
		;;
	    'export_todo')
		header
		exportTodo "${rest}"
		sleep 1 && init_todo
		;;
	    'clear')
		sleep 1 && init_todo
		;;
	    'help')
		header
		license
		usage
		;;
	    *)
		usage
	esac
	tput cup ${LINENO}
    done
    
}

@return() {
    #printf "%s\n" "${@}" >&2 >/dev/null
    printf "%s\n" "${@}"
    return 0;
}

@die() {
    #printf "%s\n" "${@}" >&2 >/dev/null
    printf "%s\n" "${@}"
    return 1;
}

__noRepeat() {
    # this function does not do much, but it kind of fix a bug
    local callback="${1}" _retString command;
    
    read -a callbackArray <<<"${callback}"
    
    #destructure ${callbackArray[@]} "command,argument"
    
    command="${callbackArray[@]:0:1}"
    argument="${callbackArray[@]:1}"
    
    if [[ ! -z "${argument}" ]];then
	_retString=$($command "${argument}")
    else	
	_retString=$($command)
    fi
    
    [[ ! -z "${_retString}" ]] && { @return "${_retString}";}

    unset command argument
}
<<'EOF'
xstat() {
    # since stat does not show the birth time of a file
    #  a little hack was gotten from
    #     http://moiseevigor.github.io/software/2015/01/30/get-file-creation-time-on-linux-with-ext4/
    local target crtime fs inode
    for target in "${@}"; do
	inode=$(ls -di "${target}" | cut -d ' ' -f 1)
	fs=$(df "${target}"  | tail -1 | awk '{print $1}')
	crtime=$(sudo debugfs -R 'stat <'"${inode}"'>' "${fs}" 2>/dev/null | 
			grep -oP 'crtime.*--\s*\K.*')
	printf "%s\t%s\n" "${crtime}" "${target}"
    done
}
EOF

# don't create todo if it already exists
addTodo::IfExists() {
    
    local checkagainst="${1}"

    {
	[[ -f "${TODO_DIR}${checkagainst}" ]] 
	
    } && {
	@return "BTDSH_EXIST"
	return 1;
    } || {
	@return "BTDSH_NOEXIST"
	return 0;
    }
     
}

# add todo
addTodo() {
    
    local todo="$1" _presentDate hashvalue _retString
    
    [[ -z "$todo" ]] && {
	@return "Incomplete requirement for adding todo"
	return $?
    }


    test ! -d "${TODO_DIR}" && mkdir ${TODO_DIR}
    
    # xstat does not work as expected
    #   that is why i decided not to work with the birth time of the todo file
    #     instead i decided to use the builtin date command
    
    _presentDate=$(date "+%B_%d_%Y")
    
    hashvalue="$(sha256deep <<<${todo})"
    # append the date of creation of todo
    hashvalue+="--${_presentDate}"
    
    _retString=$(__noRepeat "addTodo::IfExists ${hashvalue}");
    
    [[ ${_retString} == "BTDSH_EXIST" ]] && {
	@die "${todo} already exists, choose a new name"
	return $?
    }

    addTodo::SaveTodo \
	"${TODO_DIR}${hashvalue}" "${todo}"
    
}

# save todo
addTodo::SaveTodo() {
    local fileToSaveTo="${1}" todo="${2}"
    > "${fileToSaveTo}"

    printf "${todo}" >> "${fileToSaveTo}"
    printf "%s addedd\n" "${todo}"
}

# iterate todo and grab them by date
#  this was done to prevent repititon
iterateByDate() {
    
    local _typeOfOp="${1}" _isFound;
    
    readWhenTodo "${_by}" 1>/dev/null
    
    for _kk in "${_HOLD_FILE_NAME[@]}";do
	
	_saveRelativePath="${_kk##*/}"

	read ___ < "${TODO_DIR}${_saveRelativePath}"

	[[ "${_typeOfOp}" == "nodelete" ]] && {
	    
	    [[ "${_saveRelativePath}" =~ ^_ ]] && {
		@return "${___} has already been marked completed"
		continue ;
	    }
	    
	    mv "${_kk}" "${TODO_DIR}_${_kk##*/}"
	    @return "${___} has been marked as completed"
	    
	} || {
	    [[ "${_typeOfOp}" == "delete" ]] && {
		
		if [[ -f "${_kk}" ]];then
		    _isFound=1;
		    rm -f "${_kk}"
		    @return "${___} has been deleted"		    
		fi

	    }
	}
	
    done
    {
	(( _isFound == 0 )) && [[ "${_typeOfOp}" == "delete" ]]
    } && {
	@return "Nothing was deleted is either todo is empty or date format is wrong"
    }
}
# iterate todo and grab them by title
#  this was done to prevent repititon
iterateByTitle() {
    local _typeOfOp="${1}"
    readAllTodos 1>/dev/null
    _byHash=$(sha256deep <<<"${_by,,}")
    
    for _kk in "${_HOLD_FILE_NAME[@]}";do
	_saveRelativePath="${_kk%%-*}"
	_saveRelativePath="${_kk##*/}"
	read ___ < "${TODO_DIR}${_saveRelativePath}"
	{
	    [[ "${_byHash}" == "${_saveRelativePath%%-*}" ]] || \
		[[ "_${_byHash}" == "${_saveRelativePath%%-*}" ]]
	} && {
	    
	    isEqual=1

	    [[ "${_typeOfOp}" == "nodelete" ]] && {
		
		[[ "${_saveRelativePath}" =~ ^_ ]] && {
		    
		    @return "${___} has already been marked completed"
		    continue ;
		    
		}
		
		mv "${_kk}" "${TODO_DIR}_${_kk##*/}"
		@return "${___} has been marked as completed"
		
	    } || {
		
		[[ "${_typeOfOp}" == "delete" ]] && {
		    rm -f "${_kk}"
		    @return "${___} has been deleted"
		}
		
	    }
	}
	
    done
    
    (( isEqual == 0 )) && {
	@return "${_by} not found"
    }
}

# mark a todo as completed
markCompleted() {
    local _byWhat="${1}" _by="${2}" _saveRelativepath _kk _isEqual=0 _byHash _length;
    
    {
	(( _length < 2 )) && [[ -z "${_byWhat}" ]]
	    
    } && {
	@die "insufficent argument passed"
	return $?
    }

    case ${_byWhat} in
	'date')
	    [[ -z "${_by}" ]] && {
		@die "specifiy a date to search for"
		return $?;
	    }	    
	    printf "%s\n" "$(iterateByDate "nodelete")"  
	    ;;
	'title')
	    [[ -z "${_by}" ]] && {
		@die "specifiy a title to search for"
		return $?;
	    }
	    printf "%s\n" "$(iterateByTitle "nodelete")"
	    ;;
	*)
	    @die "invalid command supported commands are { title, date }"
	    return $?;
	;;
    esac
    declare +a _HOLD_FILE_NAME
    unset ___ _kk
}
# read the content of todo
readTodoContent() {
    read _todoContent < "${_files}"

    # if a todo starts with _ it is completed
    [[ "${_files##*/}" =~ ^_ ]] && {
	printf "%d.\t[completed]\t%s\n" "${num}" "${_todoContent}"

     } || {
	printf "%d.\t[         ]\t%s\n" "${num}" "${_todoContent}"
    }
}
# read all todos 
readAllTodos() {
    declare -i num=0;
    _HOLD_FILE_NAME=()
    for _files in "${TODO_DIR}"*;do
	
	[[ -f "${_files}" ]] && {
	    
	    # for some reason this does not work
	    #while IFS="" read line;do
	    #	echo $line
	    #done < "${_files}"
	    : $((num++))
	    _HOLD_FILE_NAME+=( "${_files}" )
	    printf "%s\n" "$(readTodoContent)"
	}
    done
}
# read todo by creation date
readWhenTodo() {
    
    local _date="${1}" _specifiedDate isEqual=0 _joinedDate _files _fileData _monthLength;

    declare -A _MONTHS=(
	["JAN"]="JANUARY"
	["FEB"]="FEBURARY"
	["MAR"]="MARCH"
	["APR"]="APRIL"
	["MAY"]="MAY"
	["JUNE"]="JUNE"
	["JULY"]="JULY"
	["AUG"]="AUGUST"
	["SEPT"]="SEPTEMBER"
	["OCT"]="OCTOBER"
	["NOV"]="NOVEMBER"
	["DEC"]="DECEMBER"
    )
    
    [[ -z "${_date}" ]] && {
	@return "BTDSH_NOARG"
	return 1;
    }

    read -a _specifiedDate <<<"${_date//:/ }"

    destructure ${_specifiedDate[@]} "month,date,year"
    
    for _month in "${!_MONTHS[@]}";do
	
	{
	    [[ "${_month,,}" == "${month,,}" ]] || [[ "${month,,}" == "${_MONTHS[$_month],,}" ]]
	    
	} && {
	    isEqual=1;
	    break;
	    
	}
	continue;
	
    done

    # check if date format specified is supported by this script
    {
	(( isEqual == 0 )) || \
	    [[ ! "${year}" =~  ^[[:digit:]]{4}$ ]] || \
	    [[ ! "${date}" =~ ^[[:digit:]]{2}$ ]]
	
    } && {
	@return "BTDSH_INVALIDDATE"
	return 1;
    }
    
    _joinedDate="${month}:${date}:${year}"
    declare -i num=0;
    _HOLD_FILE_NAME=()
    for _files in "${TODO_DIR}"*;do
	_fileDate="${_files##*--}"
	_fileDateMonth="${_fileDate%%_*}"
	
	# did this here to avoid repition
	_monthLength="${#month}"
	_fileDate="${_fileDate//_/:}"
	
	{
	    # month length is less equal to 3
	    #  this was done incase the user of this script specified a short form name
	    #  NOTE:- June and July short form is the same as their long form
	    (( _monthLength == 3 ))
	} && {
	    _shortName="${_fileDateMonth:(-${#_fileDateMonth}):3}"
	    _fileFullDate="${_shortName,,}:${_fileDate#*:}"

	    if [[ "${_fileFullDate}" == "${_joinedDate}" ]];then
		: $((num++))
		_HOLD_FILE_NAME+=( "${_files}" )
		printf "%s\n" "$(readTodoContent)"
	    fi
	    
	} || {

	    if [[ "${_fileDate,,}" == "${_joinedDate,,}" ]];then
		: $((num++))
		_HOLD_FILE_NAME+=( "${_files}" )
		printf "%s\n" "$(readTodoContent)"
	    fi
	    
	}
	
    done

    unset month date year
    
}

# read todo by
#  1. completed
#  2. when
#  3. notcompleted
#  4. all | null
readTodo() {
    local readType="${1}" _files _todoContent _compl;

    {
	[[ ! -d "${TODO_DIR}" ]] || [[ -z "$(ls ${TODO_DIR})" ]]
    } && {
	@die "no todo exits"
	return $?;
    }
    
    
    case $readType in
	'completed')
	    declare -i num=1;
	    for _compl in "${TODO_DIR}"*;do
		read _todoContent < "${_compl}"
		_compl=${_compl##*/}
		[[ "${_compl}" =~ ^_ ]] && {
		    printf "%d.\t[completed]\t%s\n" "${num}" "${_todoContent}"
		    : $((num++))
		}

	    done
	;;
	'when')
	    local _date="${2}"
	    
	    local _retString="$(__noRepeat "readWhenTodo ${_date}")";

	    case "${_retString}" in
		"BTDSH_INVALIDDATE")
		    @die "invalid date format specified"
		    return $?
		    ;;
		"BTDSH_NOARG")
		    @die "a date is needed"
		    return $?
		    ;;
		*)
		    printf "%s\n" "${_retString}"
		    ;;
	    esac
	    
	    ;;
	'notcompleted')
	    declare -i num=1;
	    for _compl in "${TODO_DIR}"*;do
		read _todoContent < "${_compl}"
		_compl=${_compl##*/}
		[[ ! "${_compl}" =~ ^_ ]] && {
		    printf "%d.\t[         ]\t%s\n" "${num}" "${_todoContent}"
		    : $((num++))
		}
	    done	    
	    ;;
	'all'|'')
	    local _retString=$(__noRepeat "readAllTodos");
	    printf "%s\n" "${_retString}"
	    ;;
	*)
	    @die "type $readType is not valid, only { completed, all, notcompleted, when } is supported"
	    return $?
    esac

}


# delete a todo
deleteTodo() {
    
    local _byWhat="${1}" _by="${2}" _length="${#@}"
    
    {
	(( _length < 2 )) && [[ -z "${_byWhat}" ]]
	    
    } && {
	@die "insufficent argument passed"
	return $?
    }
    
    case ${_byWhat} in
	'all')
	    
	    local _runOrNot="${2}"
	    case "${_runOrNot}" in
		'')
		    @die \
		     "What you are about to do is dangerous" \
		     "use dry_run to see what this command does"
		    return ;
		    ;;
		'dry_run')
		    for _dRun in "${TODO_DIR}"*;do
			printf "%s\n" "rm -f ${_dRun%%-*}"
		    done
		    ;;
		'rm')
		    for _dRun in "${TODO_DIR}"*;do
			printf "Removed\t%s\n" "${_dRun%%-*}"
			rm "${_dRun}" 2>/dev/null
		    done
		    ;;
	    esac
	    
	;;
	'date')
	    [[ -z "${_by}" ]] && {
		@die "specifiy a date to search for"
		return $?;
	    }	    
	    printf "%s\n" "$(iterateByDate "delete")"
	;;
	'title')
	    [[ -z "${_by}" ]] && {
		@die "specifiy a title to search for"
		return $?;
	    }
	    printf "%s\n" "$(iterateByTitle "delete")"
	;;
	*)
	    @die "invalid command supported commands are { title, date }"
	    return $?;
	;;
    esac
}

# export todo as json
exportTodo() {
    local _exportAs="${1}" _todos;
    case ${_exportAs} in
	'json')
	    
	    local _json="{\n"
	    
	    for _todos in "${TODO_DIR}"*;do
		
		# this variable will contain the pathname of the todo excluding the date
		_todoPath="${_todos%%-*}" 
		
		# this variable will contain only the date
		_dateOfCreation="${_todos##*-}"
		
		# this varialbe will contain the todos name
		_todoName="${_todoPath##*/}" 
		
		# strip of any _ in the hash value
		_todoName="${_todoName##*_}"
		
		# just get 8 characters from the todo since
		#     a little change in a plain text will lead to a big change in the hash valueW
		_json+="\"${_todoName:(-${#_todoName}):8}\":["

		
		read _todoContent < "${_todos}"
		
		[[ "${_todoPath##*/}" =~ ^_ ]] && {
		    
		    _json+="\
{\n\
\t\"completed\":true,\n\
\t\"content\":\"${_todoContent}\",\n\
\t\"dateOfCreation\":\"${_dateOfCreation//_/:}\
\"\n\
\t}],\n"
		    		    
		} || {
		    
		    _json+="\
{\n\
\t\"completed\":false,\n\
\t\"content\":\"${_todoContent}\",\n\
\t\"dateOfCreation\":\"${_dateOfCreation//_/:}\
\"\n\
\t}],\n"
		    
		}
		
	    done
	    
	    <<'EOF'
{
   "hash": [{
         "completed": true,
         }],
}

if hash is the last property of the JSON object the leading "," after the "]" is striped off

EOF
	    _json="${_json%,*}"
	    
	    _json+="\n}"

	    printf "${_json}\n" > .btdsh.json
	    
	;;
	*)
	    @die "${_exportAs} is not supported"
	    return $?
    esac
}
#addTodo "write download manager with Tcl"
#readTodo all
#readTodo when "mar 18 2017"
#readTodo when "januaryadsf 12 2017"
#readTodo when "january 12 2017"
#markCompleted "title" "visit tammah markets"
#markCompleted "date" "mar 18 2017"
#readTodo when "mar 18 2017"
#readTodo completed
#deleteTodo "title" "visit tammah village"
#deleteTodo "date" 'mar 18 2017'
#deleteTodo all 
#exportTodo "json"


# getopts did not do what i want
SUBCOMMAND="${1}"
shift 
case "${SUBCOMMAND}" in
    '-a'|'--add-todo'|'add_todo')
	addTodo "${@}"
    ;;
    '-r'|'--read-todo'|'read_todo')
	readTodo "${@}"
    ;;    
    '-d'|'--delete-todo'|'delete_todo')
	deleteTodo "${@}"
    ;;
    '-m'|'--mark-completed'|'mark_completed')
	markCompleted "${@}"
    ;;
    '-e'|'--export-todo'|'export_todo')
	exportTodo "${@}"
    ;;
    '-i'|'--interactive'|'interactive'|'')
	init_todo;
	;;
    '-h'|'--help'|'help')
	header
	license
	usage
	;;
    *)
	header
	license
	usage
esac
