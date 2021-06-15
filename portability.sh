#!/usr/bin/env sh

# Protect against double loading and register dependencies
if printf %s\\n "${MG_MODULES:-}"|grep -q "portability"; then
  return
else
  MG_MODULES="${MG_MODULES:-} portability"
fi

# Set this to force home-made implementation in favour of local builtin
__MG_PORTABILITY_FORCE=${__MG_PORTABILITY_FORCE:-0}

if ! printf %s\\n "${MG_MODULES:-}"|grep -q "locals"; then
  printf %s\\n "This module requires the locals module" >&2
fi

b64_encode() { base64; }
b64_decode() {
  if [ "$(uname -s)" = "Darwin" ]; then
    base64 -D; # Mac takes -D or --decode
  else
    base64 -d; # Alpine/budybox does not understand --decode
  fi
}


# This is an expansion safe envsubst implementation in pure-shell and inspired
# by https://stackoverflow.com/a/40167919. It uses eval in a controlled-manner
# to avoid side-effects.
# shellcheck disable=SC2120
mg_envsubst() {
  stack_let line
  while IFS= read -r line || [ -n "$line" ]; do  # Read, incl. non-empty last line
    stack_let _lineEscaped
    stack_let _lineResolved
    stack_let _oldstate

    # Transform everything that looks like an environment variable (all
    # caps, no first digit) to its {} equivalent. This transform
    # understands \$ quoting, but will fail within single quotes. Then
    # escape ALL characters that could trigger an expansion.
    IFS= read -r _lineEscaped << EOF
$(printf %s "$line" | sed -E -e 's/([^\\])\$([A-Z_][A-Z0-9_]*)/\1\${\2}/g' -e 's/^\$([A-Z_][A-Z0-9_]*)/\${\1}/g' | tr '`([$' '\1\2\3\4')
EOF
    # ... then selectively reenable ${ references
    _lineEscaped=$(printf %s\\n "$_lineEscaped" | sed -e 's/\x04{/${/g' -e 's/"/\\\"/g')
    # Disable unset errors to ensure we output something (with empty
    # value for var)
    _oldstate=$(set +o); set +u
    # At this point, eval is safe, since the only expansion left is for
    # ${} contructs. Perform the eval, variables that do not exist will
    # be replaced by an empty string.
    _lineResolved=$(eval "printf '%s\n' \"$_lineEscaped\"")
    # Restore set state
    set +vx; eval "$_oldstate"
    # and convert back the control characters to the real chars.
    printf %s\\n "$_lineResolved" | tr '\1\2\3\4' '`([$'
    stack_unlet _lineEscaped _lineResolved _oldstate
  done
  stack_unlet line
}

# Install mg_envsubst automatically as envsubst when it does not exist.
if [ "$__MG_PORTABILITY_FORCE" = "1" ] || ! command -v envsubst >/dev/null; then
  alias envsubst=mg_envsubst
fi