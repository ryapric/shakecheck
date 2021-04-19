#!/usr/bin/env sh
set -eu

# Lintable Makefile is first script arg
makefile="$1"
if [ ! -f "${makefile}" ]; then
  printf "ERROR: %s is not a valid file\n" "${makefile}" > /dev/stderr
  exit 1
fi
printf ">Checking Makefile at %s...\n" "$(realpath "${makefile}")"

# Grab the defined shell -- users are expected to have set a SHELL, else
# shakecheck will not run
shell=$(
  grep -E '^SHELL' "${makefile}" \
  | grep -o '/.*' \
) || {
  printf "WARNING: 'SHELL' not found; shakecheck will use POSIX 'sh' as the Makefile shell. You can override by setting the 'SHELL' Make variable\n" > /dev/stderr
  shell='/usr/bin/env sh'
}

# Build shebang for the implied shell script
shebang="#!${shell}"

# grab list of Makefile targets
grep -E -o '^[^#[:space:]]+:' "${makefile}" | sed 's/://' > /tmp/targets

# Build the implicit shell script, and lint. Note that we're ignoring SC2096
# globally, since you may have `set` global shell options in your SHELL Make
# variable (I mean... I do this)
while read -r target; do
  printf "=>Checking target '%s'..." "${target}"
  printf "%s\n" "${shebang}" > /tmp/shakecheck
  make -C "$(dirname "${makefile}")" -n "${target}" >> /tmp/shakecheck
  if grep 'Nothing to be done for ' /tmp/shakecheck; then
    continue
  fi
  shellcheck --exclude=SC2096 /tmp/shakecheck && printf "OK\n"
done < /tmp/targets
