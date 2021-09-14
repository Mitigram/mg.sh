#!/usr/bin/env sh

# Declare MG_LIBPATH
if [ -n "${BASH:-}" ]; then
  # shellcheck disable=SC3028,SC3054 # We know BASH_SOURCE only exists under bash!
  MG_LIBPATH=${MG_LIBPATH:-$(dirname "${BASH_SOURCE[0]}")}
else
  # Introspect by asking which file descriptors the current process has opened,
  # removing /dev, the last files is the source to this script, as long as this
  # is called ealy on in the script. This is an evolution of
  # https://unix.stackexchange.com/a/351658
  MG_LIBPATH=${MG_LIBPATH:-$(dirname "$(lsof -p $$ -Fn0 2>/dev/null |
                                        tr -d '\0' |
                                        grep -vE '^f[0-9]+n/dev' |
                                        tail -n 1 |
                                        sed -E 's/^f[0-9]+n//')")}
fi

# Protect against double loading
if printf %s\\n "${MG_MODULES:-}"|grep -q "bootstrap"; then
  return
else
  MG_MODULES="${MG_MODULES:-} bootstrap"
fi

path_split() {
  printf %s\\n "$1" | awk '{split($1,DIRS,/:/); for ( D in DIRS ) {printf "%s\n", DIRS[D];} }'
}

path_search() {
  # shellcheck disable=SC3043 # local exists in most shell implementations anyhow
  local _d || true
  for _d in $(path_split "$1"); do
    if [ -f "${_d}/${2}" ]; then
      printf %s/%s\\n "$_d" "$2"
      unset _d
      return
    fi
  done
}

bootstrap() {
  MG_LIBPATH="$1"
}

has_module() {
  # shellcheck disable=SC3043 # local exists in most shell implementations anyhow
  local _module || true

  for _module; do
    if printf %s\\n "${MG_MODULES:-}"|grep -q "$_module"; then
      unset _module
      return 0
    fi
  done
  unset _module
  return 1
}

module() {
  if [ -z "${MG_LIBPATH:-}" ]; then
    echo "Provide MG_LIBPATH, a colon-separated search path for scripts, possibly via bootstrap function" >& 2
    exit
  else
    # shellcheck disable=SC3043 # local exists in most shell implementations anyhow
    local _module _d || true

    for _module; do
      for _d in $(path_split "$MG_LIBPATH"); do
        if has_module "$_module"; then
          unset _module; # Use the variable as a marker for module found.
          break
        elif [ -f "${_d}/${_module}.sh" ]; then
          # Log if we can
          if type log_debug | head -n 1 | grep -q function; then
            log_debug "Sourcing ${_d}/${_module}.sh"
          fi
          # shellcheck disable=SC1090
          . "${_d}/${_module}.sh"

          # Add module to list of known modules
          if ! printf %s\\n "${MG_MODULES:-}"|grep -q "$_module"; then
            MG_MODULES="${MG_MODULES:-} $_module"
          fi

          unset _module; # Use the variable as a marker for module found.
          break
        fi
      done
      if [ -n "${_module:-}" ]; then
        echo "Cannot find module $_module in $MG_LIBPATH !" >& 2
        exit 1
      fi
    done
    unset _d
  fi
}
