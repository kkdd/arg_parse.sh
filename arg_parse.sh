#!/bin/sh

# constants
TRUE="true"
NINDENT=2
VALUE_IN_SAME=0  # extract value from a connected form (-n1, --num1)
VALUE_IN_NEXT=1  # extract value from an unconnected form (-n 1, --num 1)
EXTRACT_FAILED=2 # extract failed (missing or invalid value)
UNDEFINED_VALUE="UNDEFINED VALUE"  # used in the case of extract failed

# default values (long option names are used as the corresponding variable names)
loops_var=1  # the suffix of _var is appended for variables
# debug_enabled=$TRUE  # the suffix of _enabled is appended for Boolean
warning=""
missing=""

# command requirements
commands_required="fmt"
commands_gnu=""  # GNU commands required

# messages
PROGNAME=${0##*/}
USAGE="Usage:
  $PROGNAME [options] [ARGUMENT...]"
OPTIONS="Options:
  -h|--help          Show this usage and exit.
  -d|--debug         Enable debug mode.
  -l|--loops N       Set the number of loops (default: $loops_var).
  -m|--mammal NAME   Set mammal name.
  -S                 Enable s-flag.
  -T T               Set t-value."
DESCRIPTION="Description:
Parse command-line arguments."
EXAMPLES="Examples:
  dash $PROGNAME --debug --loops=2 --mammal=cat,dog I II III"
WARNING_HEAD="**Warning:** Type \"$PROGNAME --help\" for usage."

# functions
append_warning_f() {
  [ -z "$warning" ] && warning="$1" || warning="$warning$(printf '\n%s' "$1")"
}

extract_opt_value_in_same_f() {  # Extract optional argument value from the connected forms such as -n1, --num1, -n=1, or --num=1 using option prefix tokens -n--num asigned by $1.
  opt_value="$2"  # initial value (from current argument)
  prefix_tokens="$(printf '%s' "$1" | sed 's/\([^ -]\)-/\1 -/g')"  # split tokens by inserting a space before '-'.
  prefix_tokens="$prefix_tokens ="  # append "=" as a delimiter for stripping
  for p in $prefix_tokens; do
    opt_value=${opt_value#"$p"}  # extract the value by stripping prefix tokens
  done
  printf '%s' "$opt_value"
}

extract_opt_value_f() {  # Extract optional argument value futhermore from the unconnected forms such as -n 1, --num 1, -n= 1, or --num= 1 also using option prefix tokens -n--num asigned by $1.
  opt_value="$(extract_opt_value_in_same_f "$1" "$2")"  # default at start
  value_from=$VALUE_IN_SAME
  if [ -z "$opt_value" ]; then
    opt_value="$3"  # the value may reside at the next place
    value_from=$VALUE_IN_NEXT
    if [ "${3+z}" != z ]; then
      opt_value="$UNDEFINED_VALUE"; value_from=$EXTRACT_FAILED
    else
      case "$opt_value" in
        -*)  opt_value="$UNDEFINED_VALUE"; value_from=$EXTRACT_FAILED ;;
      esac
    fi
  fi
  printf '%s' "$opt_value"
  return $value_from  # caller will use it as an additional shift except failed
}

# parse optional arguments
 # shellcheck disable=SC2034  # variables unused
while [ $# -gt 0 ]; do
   case "$1" in
    -h|--help)      help_enabled=$TRUE;;
    -d|--debug)     debug_enabled=$TRUE;;
    -l*|--loops*)   loops_var=$(extract_opt_value_f -l--loops "$@");;
    -m*|--mammal*)  mammal_var=$(extract_opt_value_f -m--mammal "$@");;
    -S)             s_enabled=$TRUE;;
    -T*)            t_var=$(extract_opt_value_f -T "$@");;
    -[!-][!-]*)     # split combined short options: -abc → -a -bc
                    rest_flags=${1#??}; first_flag=${1%"$rest_flags"}; shift;
                    set -- "$first_flag" "-$rest_flags" "$@"; continue;;
    --)             shift; break;;
    -*)             append_warning_f "Unknown option: '$1'";;
    *)              break;;
  esac
  shift_additional=$?
  if [ $shift_additional -lt $EXTRACT_FAILED ]; then
    shift $shift_additional  # 0: default, 1: extract_opt_value_f successfully extracts the next arg
  else
    append_warning_f "Option '${1%=}' requires an argument"
  fi
  shift
done

# confirmations
for e in "$@"; do
  case "$e" in -*) append_warning_f "Argument value should not begin with \"-\": '$e'";; esac
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
text_style_f() { ESC=$(printf '\033'); printf "${ESC}[%dm" "$1"; }
NORMALFACE="$(text_style_f 0)" 
if [ -n "$help_enabled" ]; then
  printf '%s\n' "$USAGE"
  if [ -n "$DESCRIPTION" ]; then
    format_text_block_f() {
      fmt_f() {
        LINE_WIDTH=80  # the traditional column width
        w="-w$((LINE_WIDTH - 1))"  # option for fmt
        fmt "$w" </dev/null >/dev/null 2>&1 || unset w  # dry run for the option
        fmt "$w"
      }
      awk -v n="$NINDENT" '/^[A-Z].*:$/ {print; next}{printf "%*s%s\n", n, "", $0}' | fmt_f
    }
    printf '\n%s\n' "$DESCRIPTION" | format_text_block_f
  fi
  if [ -n "$OPTIONS" ]; then
    decorate_f() {
      [ -t 1 ] || { cat; return; }  # stop decoration
      GREEN="$(text_style_f 36)" BAR="$GREEN|$NORMALFACE" UNDERLINE="$(text_style_f 4)"
      sed "s/|/$BAR/g" |
      sed "s/\( \)\([A-Z][A-Z]*\)\([^ A-Z]*\)\(  \)/\1${UNDERLINE}\2${NORMALFACE}\3\4/"  # underline uppercase variable names
    }
    printf '\n%s\n' "$OPTIONS" | decorate_f
  fi
  [ -n "$EXAMPLES" ] && printf '\n%s\n' "$EXAMPLES"
  if [ -n "$commands_required" ]; then
    s="$(printf '%s' "$commands_required" | sed "s/ /, /g")"
    printf '\n%s\n' "Required commands: $s"
  fi
fi
if [ -n "$warning" ]; then
  magenta_f() {  #  emphasize **strings** as colored magenta
    MAGENTA="$(text_style_f 31)"
    sed "s/\*\*\([^_]*\)\*\*/${MAGENTA}\1${NORMALFACE}/g"
  }
  printf '%s\n' "$WARNING_HEAD" | magenta_f  >&2
  printf '%s\n' "$warning" | sed 's/^/- /' >&2
  exit 1
fi
[ -n "$help_enabled" ] && exit

# main
