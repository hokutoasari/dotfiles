#!/bin/sh

declare -r GITHUB_REPOSITORY="hokutoasari/dotfiles"
declare dotfilesDirectory="$HOME/dotfiles"
declare -r DOTFILES_ORIGIN="git@github.com:$GITHUB_REPOSITORY.git"
declare -r DOTFILES_TARBALL_URL="https://github.com/$GITHUB_REPOSITORY/tarball/master"
declare -r DOTFILES_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/master/scripts/utils.sh"

git_connect_test() {
    ssh -t git@github.com &> /dev/null
    return $?
}

verify_dotfiles_directory() {
    ask_for_confirmation "Your dotfiles directory is '${dotfilesDirectory}'?"
    if ! answer_is_yes; then
        dotfilesDirectory=""
        while [ -z "${dotfilesDirectory}" ]; do
            ask 'Please specify another location for the dotfiles (path): '
            dotfilesDirectory="$(get_answer)"
            # if start with "/" then clear ${dotfilesDirectory}
            if [ ! -z "${dotfilesDirectory}" ]; then
                local head
                head=$(echo $dotfilesDirectory | cut -c 1)
                if [ ${head} == "/" ]; then
                    dotfilesDirectory=""
                    print_info "Can not use absolute path. Please input relative path from you HOME(${HOME})"
                fi
            fi
            # if start with "~/" then clear ${dotfilesDirectory}
            if [ ! -z "${dotfilesDirectory}" ]; then
                local head2char
                head2char=$(echo $dotfilesDirectory | cut -c 1-2)
                if [ ${head2char} == "~/" ]; then
                    dotfilesDirectory=""
                    print_info "Can not use ~/ path. Please input relative path with you HOME(${HOME})"
                fi
            fi
        done
    fi

    pushd ~/ > /dev/null
    while [ -e "${dotfilesDirectory}" ]; do
        ask_for_confirmation "'$dotfilesDirectory' already exists, do you want to overwrite it?"
        if answer_is_yes; then
            rm -rf ${dotfilesDirectory}
            break
        else
            dotfilesDirectory=""
            while [ -z "$dotfilesDirectory" ]; do
                ask 'Please specify another location for the dotfiles (path): '
                dotfilesDirectory="$(get_answer)"
                # if start with "/" then clear ${dotfilesDirectory}
                if [ ! -z "${dotfilesDirectory}" ]; then
                    local head
                    head=$(echo $dotfilesDirectory | cut -c 1)
                    if [ ${head} == "/" ]; then
                        dotfilesDirectory=""
                        print_info "Can not use absolute path. Please input relative path from you HOME(${HOME})"
                    fi
                fi
                # if start with "~/" then clear ${dotfilesDirectory}
                if [ ! -z "${dotfilesDirectory}" ]; then
                    local head2char
                    head2char=$(echo $dotfilesDirectory | cut -c 1-2)
                    if [ ${head2char} == "~/" ]; then
                        dotfilesDirectory=""
                        print_info "Can not use ~/ path. Please input relative path with you HOME(${HOME})"
                    fi
                fi
            done
        fi
    done
    popd > /dev/null
}

git_clone() {
    # git connect test
    if ! git_connect_test; then
        print_error "Can not connect github.com, Please adding a new SSH key to your GitHub account."
        return 1
    fi

    # verify dotfiles directory
    verify_dotfiles_directory

    # execute clone
    pushd ~/ > /dev/null
    git clone ${DOTFILES_ORIGIN} ${dotfilesDirectory} > /dev/null
    print_result $? "Create '$dotfilesDirectory'" 'true'
    popd > /dev/null

    print_info "Clone was success: ${dotfilesDirectory}"

    return 0
}

extract() {
    local archive="$1"
    local outputDir="$2"

    pushd ~/ > /dev/null
    if command -v 'tar' &> /dev/null; then
        tar -zxf "$archive" --strip-components 1 -C "$outputDir"
        local rs=$?
        popd > /dev/null
        return ${rs}
    fi
    popd > /dev/null

    return 1
}

download_dotfiles() {
    local tmp_file=$(mktemp -d -t temp)
    # download
    download "${DOTFILES_TARBALL_URL}" "${tmp_file}"
    print_result $? 'Download archive' 'true'
    printf '\n'

    # verify dotfiles directory
    verify_dotfiles_directory

    # extract dotfiles
    extract "${tmp_file}" "${dotfilesDirectory}"
    print_result $? 'Extract archive' 'true'

    # remove archive
    rm -rf "${tmp_file}"
    print_result $? 'Remove archive'
}

download() {
    local url=${1}
    local output=${2}

    if command -v "curl" &> /dev/null; then
        curl -LsSo ${output} ${url} &> /dev/null
    elif command -v "wget" &> /dev/null; then
        wget -qO ${output} ${url} &> /dev/null
    fi

    return 1
}

download_utils() {
    local tmp_file=$(mktemp -t tmp)
    download ${DOTFILES_UTILS_URL} ${tmp_file} && source ${tmp_file} && rm -rf ${tmp_file} && return 0
    return 1
}

is_supported_os() {
    declare -r SYS_NAME=$(uname)
    declare -r YUM_PATH=/usr/bin/yum
    declare -r APT_PATH=/usr/bin/apt-get
    declare -r PAC_PATH=/usr/bin/pacman

    if [ "${SYS_NAME}" == "Darwin" ]; then
        return 0
    elif [ "${SYS_NAME}" == "Linux" ]; then
        # Linux
        if [ -e ${YUM_PATH} ]; then
            return 0
        elif [ -e ${APT_PATH} ]; then
            return 0
        elif [ -e ${PAC_PATH} ]; then
            return 0
        fi
    fi

    printf "Supported platforms are Osx/RedHat/Debian/Arch."
    return 1
}

# --------------------------------------------------------------
# Main
# --------------------------------------------------------------

main() {
    # verify os
    is_supported_os || exit 1

    # cd
    cd "$(dirname "$BASH_SOURCE")"

    # load utils
    if [ -f "./scripts/utils.sh" ]; then
        source "./scripts/utils.sh" || exit 1
    else
        download_utils || exit 1
    fi

    # ask Install from git?(Y -> git / n -> download)
    ask_for_confirmation "Install from git?(Y -> git / n -> HTTPS download)"
    if answer_is_yes; then
        print_info "Install from git"
        git_clone || exit 1
    else
        print_info "Install from Https download"
        download_dotfiles || exit 1
    fi

    # cd to ${dotfilesDirectory}
    pushd ~/
    pushd ${dotfilesDirectory}

    pwd

    # popd from ${dotfilesDirectory} -> ~/
    popd > /dev/null
    popd > /dev/null

    echo "Now:: ${dotfilesDirectory}"
    echo "とりあえずココが表示されてたら正常系で処理終了しているはず"
}

main