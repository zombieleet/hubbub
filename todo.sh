#!/usr/bin/env bash

#
#  Author [zombieleet|73mp74710n]
#  Email [<zombieleetnca@gmail.com>]
#
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

__readTodoDirectory() {

    local callback="${1}"
    
    read -a callbackArray <<<"${callback}"
    
    destructure ${callbackArray[@]} "command,argument"
    
    #for files in "${TODO_DIR}"* ;do
    
    local _retString=$($command "$argument");
    
    [[ ! -z "${_retString}" ]] && { @return "${_retString}" ;}
	
#done

    unset command argument
}

readTodo() {
    local readType="${1}" _files _todoContent;

    [[ ! -d "${TODO_DIR}" ]] && {
	@die "no todo exits"
	return $?;
    }
    
    case $readType in
	'completed') ;;
	'newadded');;
	'all'|'')
	    declare -i num=0;
	    for _files in "${TODO_DIR}"*;do
		
		[[ -f "${_files}" ]] && {
		    
		    # for some reason this does not work
		    #while IFS="" read line;do
		    #	echo $line
		    #done < "${_files}"
		    
		    : $((num++))
		    read _todoContent < "${_files}"
		    [[ "${_files}" =~ ^_ ]] && {
			printf "%d.\tcompleted %s\n" "${num}" "${_todoContent}"
			continue ;
		    }
		    printf "%d.\t%s\n" "${num}" "${_todoContent}"
		    
		}
	    done
	    
	;;
    esac

}



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
    
    local todo="$1"

    [[ -z "$todo" ]] && {
	@return "Incomplete requirement for adding todo"
	return $?
    }


    test ! -d "${TODO_DIR}" && mkdir ${TODO_DIR}
    
    local hashvalue="$(sha256deep <<<${todo})"
    
    local _retString=$(__readTodoDirectory "addTodo::IfExists ${hashvalue}");
    
    
    [[ ${_retString} == "BTDSH_EXIST" ]] && {
	@die "${todo} already exists, choose a new name"
	return $?
    }

    addTodo::SaveTodo \
	"${TODO_DIR}${hashvalue}" "${todo}"
    
}

addTodo::SaveTodo() {
    
    local fileToSaveTo="${1}" todo="${2}"
    
    > "${fileToSaveTo}"
    echo $todo
    printf "${todo}" >> "${fileToSaveTo}"
}

markComplete() {
    :
}
exportTodo() {
    :
}
readTodo

