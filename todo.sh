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
set -e

. funtions.sh

readonly TODO_DIR="${HOME}/.bash_todo/"

init_todo() {
    :
}
todoComment() {
    local __writeto="${1}"
    # avoid cat :P
    while read line;do
	echo "${line}" >> "${__writeto}"
    done <<EOF 
;; This file is a btsdsh file 
;; Do not uncomment any of the content that was not commented by you
EOF
}

@return() {
    printf "%s\n" "${@}"
    return 0;
}

@die() {
    printf "%s\n" "${@}"
    return 1;
}


<<'EOF'
[[ ${_fileExt} != "btsh" ]] && {
    @return "NON_BTSH_FILE"
    continue ;
}
[[ -f ${_fileBaseName} ]] && {
    @return ""
    continue;
}
EOF



__readTodoDirectory() {
    
    local _fileExt _fileBaseName callback="${1}" ;
    
    read -a callbackArray <<<"${callback}"
    
    destructure ${callbackArray[@]} "command,argument"

    for files in "${TODO_DIR}"* ;do
	
	_fileBaseName="${files##*/}"
	_fileExt="${_fileBaseName##*.}"
	
	local _retString=$($command "$argument" "${_fileExt}" "${_fileBaseName}");
	
	[[ ! -z "${_retString}" ]] && { @return "${_retString}" ;}
	
    done

    unset command argument
}

general::analyzeFile() {
    
    local file="${1}" ext="${2}" filename="${3}"
    
    
    local _retString=$($general_IfExists "$file" "$ext" "$filename");
    

    [[ "${_retString}" != "BTDSH_EXIST" ]] && {
	@return "BTDSH_NOEXIST";
	return 1;
    }
    
    while read line;do
	echo "$line"
    done < "${file}"

    
}

addTodo::IfExists() {
    
    local checkagainst="$1" ext="$2" filename="$3"

    {	
	[[ "${ext}" == "btdsh" ]] && [[ "${filename}" == "${checkagainst}" ]]
	
    } && {
	@return "BTDSH_EXIST"
	return 0;
    }
    
}

addTodo() {
    
    local short_name="$1" content="$2" date="$3" time="$4"

    {
	[[ -z "$short_name" ]] || \
	    [[ -z "$content" ]] || \
	    [[ -z "$date" ]] || \
	    [[ -z "$time" ]]
    } && {
	@return "Incomplete requirement for adding todo"
	return $?;
    }


    test ! -d "${TODO_DIR}" && mkdir ${TODO_DIR}

    local _short_name="${short_name//[[:space:]]/_}.btdsh"
    
    local _retString=$(__readTodoDirectory "addTodo::IfExists ${_short_name}");


    [[ ${_retString} == "BTDSH_EXIST" ]] && {
	@die "${short_name} already exists, choose a new name"
	return $?
    }
    
    
    addTodo::SaveTodo \
	"${TODO_DIR}${_short_name}" "${date}__flag::date__" "${time}__flag::time__"  "${content}__flag::content__"
    
}

addTodo::SaveTodo() {
    
    local fileToSaveTo="${1}" #content="${content}" date="${date}" time="${time}"
    > "${fileToSaveTo}"
    # don't loop the file
    shift
    
    todoComment "${fileToSaveTo}"
    
    for _args ;do
	
	case ${_args} in
	    *__flag::content__* )
		printf "\n\nCONTENT: ${content/__flag::content__/}\n\n" >> "${fileToSaveTo}"
	    ;;
	    *__flag::date__* )
		printf "\n\nDATE: ${date/__flag::date__/}\n\n" >> "${fileToSaveTo}"
	    ;;
	    *__flag::time__* )
		printf "\n\nTIME: ${time/__flag::time__/}\n\n" >> "${fileToSaveTo}"
		;;
	    *)
		;;
	esac
    done
}

general_IfExists="addTodo::IfExists"

addTodo "eat bacon" "I need to eat bacon to have big teeth like my head" "$(date '+%d:%m:%y')" "$(date '+%H:%m:%S')"

