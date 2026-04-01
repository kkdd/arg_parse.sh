OPTIONS="Options:
  -h|--help          Show this usage and exit.
  -d|--debug         Enable debug mode.
  -l|--loops N       Set the number of loops (default: $loops_var)
  -m|--mammal NAME   Set mammal name.
  -S                 Enable s-flag.
  -T T               Set t-value."

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
