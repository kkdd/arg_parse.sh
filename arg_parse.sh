#!/bin/sh

# constants
TRUE="true"
NINDENT=2
VALUE_IN_SAME=0
VALUE_IN_NEXT=1
EXTRACT_FAILED=2  # for the case of invalid or missing value in parsing

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
  [ -z "$warning" ] && warning="$1" || warning="$warning$(printf '\n%s' "$1")"
}

# Extract optional argument value from the connected forms such as -n1, --num1, -n=1, or --num=1 using option prefix tokens -n--num asigned by $1.
extract_opt_value_in_same_f() {
  opt_value="$2"  # initial value (from current argument)
  prefix_tokens="$(printf '%s' "$1" | sed 's/\([^ -]\)-/\1 -/g')"  # split tokens by inserting a space before '-'.
  prefix_tokens="$prefix_tokens ="  # append "=" as a delimiter for stripping
  for p in $prefix_tokens; do
    opt_value=${opt_value#"$p"}  # extract the value by stripping prefix tokens
  done
  printf '%s' "$opt_value"
}

# Extract optional argument value futhermore from the unconnected forms such as -n 1, --num 1, -n= 1, or --num= 1 also using option prefix tokens -n--num asigned by $1.
extract_opt_value_f() {
  opt_value="$(extract_opt_value_in_same_f "$1" "$2")"  # default at start
  value_from=$VALUE_IN_SAME
  if [ -z "$opt_value" ]; then
    opt_value="$3"  # the value may reside at the next place
    value_from=$VALUE_IN_NEXT
    case "$opt_value" in
      -* | "" )  # failed
        opt_value=""
        value_from=$EXTRACT_FAILED;;
    esac
  fi
  printf '%s' "$opt_value"
  return $value_from  # caller will use it as an additional shift unless failed
}

# parsing optional arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)      help_enabled=$TRUE;;
    -d|--debug)     debug_enabled=$TRUE;;
    -l*|--loops*)   loops_var=$(extract_opt_value_f -l--loops "$@");;
    -m*|--mammal*)  mammal_var=$(extract_opt_value_f -m--mammal "$@");;
    -S)             s_enabled=$TRUE;;
    -T*)            t_var=$(extract_opt_value_f -t "$@");;
    -[!-][!-]*)     # split combined short options: -abc → -a -bc
                    rest_flags=${1#??}; first_flag=${1%"$rest_flags"}; shift;
                    set -- "$first_flag" "-$rest_flags" "$@"; continue;;
    --)             shift; break;;
    -*)             append_warning_f "Unknown option: '$1'";;
    *)              break;;
  esac
  shift_additional=$?
  if [ $shift_additional -lt $EXTRACT_FAILED ]; then
    shift $shift_additional  # 0: default, 1: extract_opt_value_f has successfully taken value from next arg
  else
    append_warning_f "Option '${1%=}' requires an argument"
  fi
  shift
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
