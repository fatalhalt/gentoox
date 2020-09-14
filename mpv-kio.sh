#!/bin/sh

uri="${1}"
cleanup() {
    kioclient_pid=$(ps -C kioclient5 -o pid=)
    [ -n "${kioclient_pid}" ] && kill ${kioclient_pid}
}

trap cleanup EXIT
use_kio() {
    $(kioclient5 cat "${1}" | mpv --player-operation-mode=pseudo-gui - > /dev/null) &
    while ps -C mpv > /dev/null; do
        sleep 2
    done
    exit 0
}

use_mpv() {
    mpv --player-operation-mode=pseudo-gui "${1}" &
    exit 0
}

command -v mpv > /dev/null || exit 1
command -v kioclient5 > /dev/null || use_mpv "${uri}"
case "${uri}" in
    fish://*)   use_kio "${uri}" ;;
    ftp://*)    use_kio "${uri}" ;;
    nfs://*)    use_kio "${uri}" ;;
    sftp://*)   use_kio "${uri}" ;;
    smb://*)    use_kio "${uri}" ;;
    webdav://*) use_kio "${uri}" ;;
    *)          use_mpv "${uri}" ;;
esac
