#! /bin/bash
# gg: a SMART directory navigation

# Usage:
# source ./gt2.sh
# Just regard "gg" as "cd", but try more:
# 1) gg <tab>
# 2) gg --
# 3) gg -<digit>

# Very useful: if you gg to that directory before, then:
# 4) gg <sub-name-in-the-dir-path>

# 5) gg <digit><tab>
# 6) gg <digit>
# If you want sub directory auto-complete, try "gg ./<tab>"

dirsv () {
  if [[ -z $1 ]]; then
      dirs -v | awk -F ' ' '{printf "%02d%s\n", $1, $2}'
  else
      dirs -v|awk -v var="$1" -F ' ' 'BEGIN{IGNORECASE=1}{printf "%03d%03d%03d %02d%s\n",match($2, var), RLENGTH, length($2),$1, $2}' | sort | grep -v '^000' | awk -F ' ' '{print $2}'
  fi
}

cd_internal ()
{
  local x2 the_new_dir adir index
  local -i cnt

  if [[ $1 ==  "--" ]]; then
    dirs -v
    return 0
  fi

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME

  index=$(printf ${the_new_dir} | sed 's/^\([0-9][0-9]\?\).*/\1/')

  if ! [[ -z ${index} ]]; then
      tmp_new_dir=$(echo ${the_new_dir} | sed 's/^[0-9][0-9]\?//')

      if [[ -z ${tmp_new_dir} ]]; then
          the_new_dir=${tmp_new_dir}
      fi

      # don't know why this time we have to prepare full path:
      [[ ${tmp_new_dir:0:1} == '~' ]] && tmp_new_dir="${HOME}${tmp_new_dir:1}"

      if [[ -d "${tmp_new_dir}" ]]; then
          the_new_dir=${tmp_new_dir}
      fi

      if [[ -z ${the_new_dir} ]]; then
          adir=$(dirs +$index)
          [[ -z $adir ]] && return 1
          the_new_dir=${adir}
      fi
  fi

  if [[ ${the_new_dir:0:1} == '-' ]]; then
    index=${the_new_dir:1}
    [[ -z $index ]] && index=1
    adir=$(dirs +$index)
    [[ -z $adir ]] && return 1
    the_new_dir=${adir}
  fi

  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  pushd "${the_new_dir}" 2>/dev/null 1>/dev/null

  if [[ $? -ne 0 ]]; then

    comlist=$(dirsv ${the_new_dir})

    echo "--- Before gg ---"
    echo "${comlist}"
    [[ -z $comlist ]] && return 1


    target_dir=$(printf ${comlist} | head -1)
    cd_internal ${target_dir}

    comlist=$(dirsv ${the_new_dir})
    echo "--- After  gg ---"
    echo "${comlist}"

    return 0
  fi


  the_new_dir=$(pwd)

  popd -n +30 2>/dev/null 1>/dev/null

  for ((cnt=1; cnt <= 30; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && break

    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == ${the_new_dir} ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null
      cnt=(${cnt}-1)
    fi
  done

  dirs -v | awk -F ' ' ' {print $2} ' > ~/.dirstack

  return 0
}

function init_dirstack()
{

    if [[ -f ~/.dirstack ]]; then
        the_cur_dir=$(pwd)
        dirs -c
        readarray -t MYARRAY < ~/.dirstack
        for (( idx=${#MYARRAY[@]}-1 ; idx>=0 ; idx-- )) ; do
            the_new_dir="${MYARRAY[idx]}"
            [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"
            pushd -n "${the_new_dir}" > /dev/null
        done
        cd_internal "${the_cur_dir}"
    fi

    dirs -v
    return 0
}

alias gg=cd_internal
alias ii=init_dirstack


function _gg {
    local curw
    COMPREPLY=()
    curw=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}

    COMPREPLY=($(compgen -W "`dirsv`" -- $curw))

    return 0
}

shopt -s progcomp
complete -o dirnames -F _gg gg

init_dirstack
