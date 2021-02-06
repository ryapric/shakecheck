#!/usr/bin/env sh
set -eu

# Lintable Makefile is first script arg
makefile="$1"

# Grab the defined shell -- users are expected to have set a SHELL, else
# shakecheck will not run
shell=$(grep -E '^SHELL' "${makefile}" | grep -o '/.*')

# Build shebang for the implied shell script
shebang="#!${shell}"

# grab list of Makefile targets
grep -E -o '^[^#[:space:]]+:' "${makefile}" | sed 's/://' > /tmp/targets

# Build the implicit shell script, and lint. Note that we're ignoring SC2096
# globally, since you may have `set` global shell options in your SHELL Make
# variable (I mean... I do this)
while read -r target; do
  printf "Checking target %s...\n" "${target}"
  # make -n "${target}"
  printf "%s\n" "${shebang}" > /tmp/shakecheck
  make -n "${target}" >> /tmp/shakecheck
  shellcheck --exclude=SC2096 /tmp/shakecheck
  # printf "\n"
done < /tmp/targets
