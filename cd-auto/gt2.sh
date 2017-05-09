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
      dirs -v|awk -v var="$1" -F ' ' 'BEGIN{IGNORECASE=1}{printf "%03d %s\n",match($2, var), $2}' | sort | grep -v '^000' | awk -F ' ' '{print $2}' | head -1
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

  index=$(printf ${the_new_dir} | sed 's/^\([0-9]\+\).*/\1/')

  if ! [[ -z ${index} ]]; then
      tmp_new_dir=$(echo ${the_new_dir} | sed 's/^[0-9]\+//')

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
    [[ -z $comlist ]] && return 1

    cd_internal ${comlist}


    return 0
  fi


  the_new_dir=$(pwd)

  popd -n +20 2>/dev/null 1>/dev/null

  for ((cnt=1; cnt <= 20; cnt++)); do
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

function cd_direct()
{

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME


  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  pushd "${the_new_dir}" > /dev/null
  [[ $? -ne 0 ]] && return 1
  the_new_dir=$(pwd)

  popd -n +10 2>/dev/null 1>/dev/null

  for ((cnt=1; cnt <= 10; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && return 0

    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == ${the_new_dir} ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null

      if [[ ${cnt} -gt 1 ]]; then
          cnt=(${cnt}-1)
      fi
    fi
  done

  return 0

}

alias gg=cd_internal


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

if [[ -f ~/.dirstack ]]; then
    readarray -t MYARRAY < ~/.dirstack
    for (( idx=${#MYARRAY[@]}-1 ; idx>=0 ; idx-- )) ; do
        cd_internal "${MYARRAY[idx]}" > /dev/null
    done
fi

dirs -v
