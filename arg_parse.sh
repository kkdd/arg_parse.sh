#!/bin/sh

# constants
TRUE="true"
NINDENT=2
N_SHIFT_INCR_FAILED=2  # in the case of invalid or missing value in parsing

# default values (long option names are used as the corresponding variable names)
loops_var=1  # the suffix of _var is appended for variables
# debug_enabled=$TRUE  # the suffix of _enabled is appended for Boolean
warning=""
missing=""

commands_required="fmt"
commands_gnu=""  # GNU commands required

PROGNAME=${0##*/}
USAGE="Usage:
  $PROGNAME [options] [ARGUMENT...]"
OPTIONS="Options:
  -h|--help          Show this usage and exit.
  -d|--debug         Enable debug mode.
  -l|--loops N       Set the number of loops (default: $loops_var)
  -m|--mammal NAME   Set mammal name.
  -S                 Enable s-flag.
  -T T               Set t-value."
DESCRIPTION="Description:
Parse command-line arguments."
EXAMPLES="Examples:
  dash $PROGNAME --debug --loops=2 --mammal=cat,dog I II III"
WARNING_HEAD="Warning: Type \"$PROGNAME --help\" for usage instructions."

# functions
append_warning_f() {
  LF=$(printf '\n_');LF=${LF%_}
  warning="${warning}${warning:+$LF}$1"
}

argv_with_shift_f() {  # Obtains optional argument value from the connected/unconnected forms such as -n1, --loops1, -n=1, --loops=1, -n 1, and --loops 1.
  n_shift_incr=0  # default value when returning as exit status
  identifiers="$(printf '%s' "$1" | sed 's/\([^-]\)-/\1 -/g')"  # split
  argv_="$2"
  for i in $identifiers "="; do argv_=${argv_#"$i"}; done  # extract the value
  if [ -z "$argv_" ]; then  # value may resides at the next positon
    argv_="$3"; n_shift_incr=1
    case "$argv_" in -*|"") n_shift_incr=$N_SHIFT_INCR_FAILED;; esac  # failed
  fi
  printf '%s' "$argv_"
  return $n_shift_incr  # 1 will be added as the shift number.
}

# parsing optional arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)      help_enabled=$TRUE;;
    -d|--debug)     debug_enabled=$TRUE;;
    -l*|--loops*)   loops_var=$(argv_with_shift_f -n--loops "$@");;
    -m*|--mammal*)  mammal_var=$(argv_with_shift_f -m--mammal "$@");;
    -S)             s_enabled=$TRUE;;
    -T*)            t_var=$(argv_with_shift_f -t "$@");;
    -[!-][!-]*)     rest_flags=${1#??}; first_flag=${1%"$rest_flags"}; shift;
                    set -- "$first_flag" "-$rest_flags" "$@"; continue;;
    --)             shift; break;;
    -*)             append_warning_f "Unknown option: '$1'";;
    *)              break;;
  esac
  if n_shift_incr=$?; [ $n_shift_incr -lt $N_SHIFT_INCR_FAILED ]; then
    shift $((n_shift_incr+1))  ## = 1 or 2 (connected or disconnected)
  else
    append_warning_f "Option '${1%=}' requires an argument"
    shift; break;
  fi
done

# confirmations
for e in "$@"; do
  case "$e" in -*) append_warning_f "Each argument should not begin with \"-\": '$e'";; esac
done

case "$(uname -s)" in
  Linux)
    for c in $commands_gnu; do
      commands_required=$commands_required" $c"
    done ;;
  Darwin) 
    for c in $commands_gnu; do
      case $c in *[!a-zA-Z0-9_]* ) continue ;; esac  # safety guard
      gnu_command="g$c"  # should be installed by using homebrew
      eval "$c() { $gnu_command \"\$@\"; }"
      commands_required=$commands_required" $gnu_command"
    done ;;
esac
for c in $commands_required; do
  command -v "$c" >/dev/null 2>&1 || missing="${missing}${missing:+ }$c"
done
[ -n "$missing" ] && append_warning_f "Required Command: $missing"

# warn or show usage instruction
if [ -n "$help_enabled" ]; then
  printf '%s\n' "$USAGE"
  if [ -n "$DESCRIPTION" ]; then
    format_text_block_f() {
      fmt_f() {
        LINE_WIDTH=80  # the traditional  width
        w="-w$((LINE_WIDTH - 1))"  # option for fmt
        fmt "$w" </dev/null >/dev/null 2>&1 || w=""  # dry run for the option
        fmt "$w"
      }
      awk -v n="$NINDENT" '/^[A-Z].*:$/ {print; next}{printf "%*s%s\n", n, "", $0}' | fmt_f
    }
    printf '\n%s\n' "$DESCRIPTION" | format_text_block_f
  fi
  [ -n "$OPTIONS" ] && printf '\n%s\n' "$OPTIONS"
  [ -n "$EXAMPLES" ] && printf '\n%s\n' "$EXAMPLES"
  if [ -n "$commands_required" ]; then
    commands_required_="$(printf '%s' "$commands_required" | sed "s/ /, /g")"
    printf '\n%s\n' "Required commands: $commands_required_"
  fi
  exit
elif [ -n "$warning" ]; then
  text_style_f() { ESC=$(printf '\033'); printf "${ESC}[%dm" "$1"; }
  NORMALFACE="$(text_style_f 0)"; MAGENTA="$(text_style_f 31)"
  printf '%s\n' "$WARNING_HEAD" |
    awk -v m="$MAGENTA" -v n="$NORMALFACE" 'sub(/^Warning:/, m "&" n)' >&2
  printf '%s\n' "$warning" | sed 's/^/- /' >&2
  exit 1
fi

# main
# for e in "$@"; do printf "%s\n" "$e"; done
