#!/usr/bin/env bash

set -eETuo pipefail

[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = default.do ]] ||
  _CRIT "redo: default.do: Illegal env"

default_do_main ()
{
  BUILD_TARGET=${1:?}
  BUILD_TARGET_BASE=$2
  BUILD_TARGET_TMP=$3

  : "${BUILD_TOOL:=redo}"

  declare STATUS BUILD_SELECT_SH

  [[ ! -e "${BUILD_SELECT_SH:=./.build-select.sh}" ]] &&
  unset BUILD_SELECT_SH || {
    . "${BUILD_SELECT_SH:?}" && STATUS=0 ||
    test "${_E_next:-196}" -eq $? || return $_
  }

  test 0 -eq ${STATUS:-1} || case "${1:?}" in
    ${HELP_TARGET:-help}|-help|-h ) ${BUILD_TOOL:?}-always &&
        echo Halp!!1
        >&2 echo Wait.. what?
        false
      ;;

    * ) _STAT 127
      _ALERT "No such target: $1"

  esac

  # End build if handler has not exit already
  exit $?
}
[[ ! ${REDO_RUNID+set} ]] ||
  default_do_main "$@"

# Id: ..                                                           ex:ft=bash:
