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

init_todo() {
    :
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

addTodo() {
    
    local todo="$1" _presentDate hashvalue _retString
    
    [[ -z "$todo" ]] && {
	@return "Incomplete requirement for adding todo"
	return $?
    }


    test ! -d "${TODO_DIR}" && mkdir ${TODO_DIR}
    
    _presentDate=$(date "+%B_%d_%Y")
    
    hashvalue="$(sha256deep <<<${todo})"
    
    hashvalue+="--${_presentDate}"
    
    _retString=$(__noRepeat "addTodo::IfExists ${hashvalue}");
    
    [[ ${_retString} == "BTDSH_EXIST" ]] && {
	@die "${todo} already exists, choose a new name"
	return $?
    }

    addTodo::SaveTodo \
	"${TODO_DIR}${hashvalue}" "${todo}"
    
}

addTodo::SaveTodo() {
    # xstat does not work as expected
    #   that is why i decided not to work with the birth time of the todo file
    #     instead i decided to use the builtin date command
    local fileToSaveTo="${1}" todo="${2}"
    > "${fileToSaveTo}"

    printf "${todo}" >> "${fileToSaveTo}"
}


iterateByDate() {
    local _typeOfOp="${1}"

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
		rm -f "${_kk}"
		@return "${___} has been deleted"
	    }
	}
	
    done
}
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

markCompleted() {
    local _byWhat="${1}" _by="${2}" _saveRelativepath _kk _isEqual=0 _byHash;

    {
	[[ -z "${_by}" ]] && [[ "${_by}" != "all" ]]
    } && {
	@die "searching by \"${_byWhat}\" requires one pattern for marking completed todo"
	return $?
    }
    case ${_byWhat} in
	'date')
	    printf "%s\n" "$(iterateByDate "nodelete")"  
	    ;;
	'title')
	    printf "%s\n" "$(iterateByTitle "nodelete")"
	    ;;
	*)
	    @die "invalid command to ${FUNCNAME} supported commands are { title, date }"
	    return $?;
	;;
    esac
    declare +a _HOLD_FILE_NAME
    unset ___ _kk
}

readTodoContent() {
    read _todoContent < "${_files}"
    [[ "${_files##*/}" =~ ^_ ]] && {
	printf "%d.\t[completed]\t%s\n" "${num}" "${_todoContent}"

     } || {
	printf "%d.\t[         ]\t%s\n" "${num}" "${_todoContent}"
    }
}

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

    read -a _specifiedDate <<<"${_date}"

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


readTodo() {
    local readType="${1}" _files _todoContent _compl;

    [[ ! -d "${TODO_DIR}" ]] && {
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
		    printf "%s" "${_retString}"
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
    esac

}

deleteTodo() {
    
    local _byWhat="${1}" _by="${2}"
    
    {
	[[ -z "${_by}" ]] && [[ "${_byWhat}" != "all" ]]
    } && {

	@die "searching by \"${_byWhat}\" requires one pattern for deleting todo"
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
	    printf "%s\n" "$(iterateByDate "delete")"
	;;
	'title')
	    printf "%s\n" "$(iterateByTitle "delete")"
	;;
	*)
	    @die "${_byWhat} is an invalid subcommand"
	    return $?
	;;
    esac
}

exportTodo() {
    :
}
#addTodo "visit tammah village"
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
