case "${1:?}" in

( all )
    set -- @assets @build
    redo-ifchange "$@" .build-select.sh &&
    redo-stamp <<< "$*"
  ;;

( Asset/*.ogg ) #
    : "$REDO_BASE/${1%.ogg}.wav"
    redo-ifchange .build-select.sh "${_:?}" &&
    >&2 ffmpeg -i "${_}" -acodec libvorbis -ab 128k -ar 44100 -ac 2 -f ogg "$REDO_BASE/$3"
  ;;

( Asset/*.wav ) #
    for x in ${1%.wav}.*
    do
      [[ -s "${x}" ]] || continue
      case "${x,,}" in *.xm|*.s3m|*.it|*.mod ) ;;
        * ) continue ;;
      esac
      >&2 echo openmpt123 --render "$REDO_BASE/${x}" &&
      >&2 openmpt123 --render "$REDO_BASE/${x}" &&
      >&2 mv -v "$REDO_BASE/${x}.wav" "$REDO_BASE/${3}" &&
      redo-ifchange "${x}" .build-select.sh || return
      break
    done
  ;;

( Asset/Font/*.ttf ) # Symlink from local system file (requires locatedb)
    : "${1:12}"
    font_file=${_:?}
    [[ -s "${REDO_BASE}/Asset/Font/${font_file}" ]] || {
      locate -ibe "$font_file" | while read -r result
      do
        [[ -s "${result}" ]] || continue
        >&2 ln -vs "${result}" "${3}"
        break
      done
      [[ -s "${3}" ]] ||
      _WARN "No font file matching: $font_file"
    }
  ;;

( @assets:tracks )
    set -- /srv/annex-local/downloads/media/audio/trackers/*.{mod,MOD,s3m,S3M,xm,XM,it,IT}
    local -a oggs
    for x
    do
      [[ -s "${x}" ]] || continue
      : "${x##*/}"
      : "${_,,}"
      [[ -s "Asset/${_:?}" ]] && : "Asset/${_}" || >&2 ln -vs "${x}" "Asset/${_}"
      oggs+=( "${_%.*}.ogg" )
    done
    redo-ifchange "${oggs[@]}" .build-select.sh
  ;;

( @assets )
    >&2 mkdir -vp Asset/Font
    set -- Asset/Font/topaz_unicode_ks13_regular.ttf
    redo-ifchange "$@" .build-select.sh &&
    redo-stamp <<< "$*"
  ;;
( @assets )
    >&2 mkdir -vp Asset
    set -- \
      @assets:tracks \
      @assets:fonts
    redo-ifchange "$@" .build-select.sh &&
    redo-stamp <<< "$*"
  ;;

( @build )
    >&2 openfl build cpp &&
    redo-ifchange Source/*.hx .build-select.sh
  ;;

  * ) return ${_E_next:-196}

esac # Id: ..                                                      ex:ft=bash:
