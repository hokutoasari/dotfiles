#!/bin/bash

print_in_green() {
    printf "\e[0;32m$1\e[0m"
}

print_in_purple() {
    printf "\e[0;35m$1\e[0m"
}

print_in_red() {
    printf "\e[0;31m$1\e[0m"
}

print_in_yellow() {
    printf "\e[0;33m$1\e[0m"
}

cmd_exists() {
    command -v "$1" &> /dev/null
    return $?
}

answer_is_yes() {
    case ${REPLY} in
		"Yes" ) return 0 ;;
		"YES" ) return 0 ;;
		"yes" ) return 0 ;;
		"y" ) return 0 ;;
		"Y" ) return 0 ;;
		"") return 0;;
		* ) return 1 ;;
	esac
}

ask() {
    print_question "$1"
    read
}

ask_for_confirmation() {
    print_question "$1 (Y/n) "
    read -n 1
    printf "\n"
}

get_answer() {
    printf "$REPLY"
}

print_info() {
    print_in_purple "\n $1\n\n"
}

print_question() {
    print_in_yellow "  [?] $1"
}
print_error() {
    print_in_red "  [✖] $1 $2\n"
}

print_success() {
    print_in_green "  [✔] $1\n"
}

print_result() {
    [ $1 -eq 0 ] \
        && print_success "$2" \
        || print_error "$2"

    return $1
}
