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

source functions.sh
readonly TODO_DIR="${HOME}/.bash_todo/"

init_todo() {
    :
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
    
    > "${TODO_DIR}${_short_name}.btdsh"
}

general_IfExists="addTodo::IfExists"
