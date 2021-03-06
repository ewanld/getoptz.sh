#! /bin/bash
# ------------------------------------------------------------------------------
# Library to parse command line arguments.
# Works with Bash version >= 4.
#
# functions/variables starting with __ are internal functions.
# Other functions/variables are part of the public API.
# ------------------------------------------------------------------------------
function getoptz_parse {
	while [[ $# -gt 0 ]]; do
		if [[ $1 == '--' ]]; then
			shift
			ARG+=("$@")
			break

		elif [[ $1 == @(-h|--help) ]]; then
			getoptz_usage 0

		elif [[ $1 =~ ^-([[:alnum:]])([[:alnum:]]+)$ ]]; then
			# case -xvf
			local short_name=${BASH_REMATCH[1]}
			# suffix is either the value of short_name, or other flags
			local suffix=${BASH_REMATCH[2]}
			__check_option_exists "$short_name"
			local canon_name=${__opt_canon_name[$short_name]}
			if [[ ${__opt_is_flag[$canon_name]} ]]; then
				local other_flags=$(echo "$suffix" | sed -r 's/(.)/-\1 /g')
				set -- "$@" -"$short_name" $other_flags
			else
				set -- "$@" -"$short_name" "$suffix"
			fi
			shift

		elif [[ $1 =~ ^-([[:alnum:]])([^=:].*)$ ]]; then
			#case -x@$^=
			local short_name=${BASH_REMATCH[1]}
			local value=${BASH_REMATCH[2]}
			set -- "$@" -"$short_name" "$value"
			shift
			
		elif [[ $1 =~ ^(-[[:alnum:]])[=:]?(.+)$ || \
			    $1 =~ ^(--[[:alnum:]_-]{2,})[=:](.+)$ ]]; then
			# case -v=1 or -v1 or -v:1 or --verbose=1 or --verbose:1
			local option_name="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[2]}"
			set -- "$@" "$option_name" "$value"
			shift

		elif [[ $1 =~ ^-([[:alnum:]])$ || \
			    $1 =~ ^--([[:alnum:]_-]{2,})$ ]]; then
			# case -v 1 or -v or --verbose or --verbose 1
			local option_name="${BASH_REMATCH[1]}"
			__check_option_exists "$option_name"
			local canon_name=${__opt_canon_name[$option_name]}
			local is_flag=${__opt_is_flag[$canon_name]:-}
			shift
			[[ $is_flag || $# -ne 0 ]] || __getoptz_invalid_args "Value expected for option $option_name!"
			if [[ $is_flag ]]; then
				value=1
			else
				value="${1:-}"
				shift
			fi
			__getoptz_eval_opt $canon_name "$value"
			
		else
			ARG+=("$1")
			shift
		fi
	done
	
	__getoptz_validate_args
	__getoptz_eval_args
	unset __opt_canon_name __opt_alias_name __opt_is_flag __opt_is_multi __opt_default_val \
			# __opt_help __opt_help_group __opt_dest __all_help_groups __arg_name \
			# __arg_multiplicity __arg_default_val __arg_help __getoptz_conf
}

function __check_option_exists {
	local option_name=$1
	[[ ${__opt_canon_name[$option_name]+x} ]] || __getoptz_invalid_args "Invalid option: $option_name!"
}

# Return the canonical name associated with the option name (long or short)
function __get_canon_name {
	local option_name=$1
	local canon_name=${__opt_canon_name[$option_name]:-}
	echo "$canon_name"
}

function __getoptz_eval_args {
	#eval arguments	
	local -i spec_idx=0
	if [[ ${#ARG[@]} -gt 0 ]]; then
		local value; for value in "${ARG[@]}"; do
			local arg_name=${__arg_name[$spec_idx]}
			local multiplicity=${__arg_multiplicity[$spec_idx]}
			case "$multiplicity" in
				1|'?')
					__getoptz_assign_variable "$arg_name" "$value"
					spec_idx+=1
					;;
				'+'|'*')
					__getoptz_array_add "$arg_name" "$value"
					;;
			esac
		done
	fi
}

function __getoptz_validate_args {
	local -r spec_arg_count=${#__arg_name[@]}
	local -r real_arg_count=${#ARG[@]}
	local -i arg_count_min=0 arg_count_max=0
	
	if [[ $spec_arg_count -gt 0 ]]; then
		local multiplicity; for multiplicity in "${__arg_multiplicity[@]}"; do	
			case "$multiplicity" in
				  1) arg_count_min+=1; arg_count_max+=1;;
				'?')                   arg_count_max+=1;;
				'*')                   arg_count_max=-1;;
				'+') arg_count_min+=1; arg_count_max=-1;;
			esac	
		done
	fi
	
	[[ $real_arg_count -ge $arg_count_min ]]                          || __getoptz_invalid_args "Expected at least $arg_count_min argument(s), got $real_arg_count!"
	[[ $real_arg_count -le $arg_count_max || $arg_count_max -eq -1 ]] || __getoptz_invalid_args "Expected at most $arg_count_max argument(s), got $real_arg_count!"
}

# Assign a value to a variable using 'eval'
#   param 1: variable name
#   param 2: value
function __getoptz_assign_variable {
	local var_name=$1
	local value=$2
	#use random limit string to reduce risk of having the string in $value by chance
	local limit_string=EOF$RANDOM$RANDOM
	eval "$var_name=\$(cat <<-\"$limit_string\"
			$value
			$limit_string
			)"
}

# Add a value to an array variable using 'eval'
#   param 1: name of the array variable
#   param 2: value
function __getoptz_array_add {
	local array_name=$1
	local value=$2
	#use random limit string to reduce risk of having the string in $value by chance
	local limit_string=EOF$RANDOM$RANDOM
	eval "$array_name+=(\"\$(cat <<-\"$limit_string\"
			$value
			$limit_string
			)\")"
}

function __getoptz_array_set_empty {
	local array_name=$1
	eval "$array_name=()"
}

function __getoptz_eval_opt {
	local canon_name=$1
	local value=$2
	OPT[$canon_name]=$value
	local opt_dest_var=${__opt_dest[$canon_name]}
	[[ $opt_dest_var ]] || return 0

	if [[ ${__opt_is_multi[$canon_name]} ]]; then
		__getoptz_array_add "$opt_dest_var" "$value"
	else
		__getoptz_assign_variable "$opt_dest_var" "$value"
	fi
}

function getoptz_usage {
	local exit_code=${1:-0}
	local script_name=$(basename "$0")
	local u='\033[4m'
	local n='\033[0m'
	# restore IFS to its default value (space+newline+tab), in case it was changed by the caller script.
	# It is necessary for 'for' loops below.
	local old_ifs=${IFS:- $'\n'$'\t'}
	IFS=' '$'\n'$'\t'

	# Usage section
	echo -ne "${n}Usage: $script_name [${u}options${n}] [--]"

	local arg_count=${#__arg_name[@]}
	local i; for i in $(seq 0 $((arg_count - 1))); do
		local multiplicity=${__arg_multiplicity[$i]}
		case "$multiplicity" in
			  1) echo -ne " $u${__arg_name[$i]}$n";;
			'?') echo -ne " [$u${__arg_name[$i]}$n]";;
			'*') echo -ne " [$u${__arg_name[$i]}$n]...";;
			'+') echo -ne " $u${__arg_name[$i]}$n...";;
		esac
	done
	echo

	# Description section
	local help_string=${__getoptz_conf[help]:-}
	if [[ $help_string ]]; then
		echo "Description:"
		echo -e "$help_string\n" | awk '{ print "    " $0 }'
	fi

	# arguments section
	if [[ ${#__arg_name[@]} -gt 0 ]]; then
		echo "Arguments:"
		local arg_count=${#__arg_name[@]}
		local i; for i in $(seq 0 $((arg_count - 1))); do
			local arg_name=${__arg_name[$i]}
			local help_string=${__arg_help[$i]}
			local default_value="${__arg_default_val[$i]}"
			local multiplicity="${__arg_multiplicity[$i]}"
			echo -ne "     $u$arg_name$n"
			if [[ $multiplicity == @('*'|'?') ]]; then echo -n "  [optional]"; fi
			if [[ $default_value ]]; then echo -n "  [Default value: $default_value]"; fi
			echo
			if [[ $help_string ]]; then echo -e "$help_string" | awk '{ print "            " $0 }'; fi
			echo
		done
	fi

	# options section
	echo -e "Options:
     -h, --help
            Display this help and exit.
"
	# display the default help group first.
	local group_name; for group_name in "$__DEFAULT_HELP_GROUP" "${!__all_help_groups[@]}"; do
		[[ $group_name == $__DEFAULT_HELP_GROUP ]] || echo "${group_name}:"
		local canon_name; for canon_name in "${!__opt_is_flag[@]}"; do
			[[ $group_name == ${__opt_help_group[$canon_name]} ]] || continue
			local alias_names=${__opt_alias_name[$canon_name]:-}
			local help_string=${__opt_help[$canon_name]}
			local is_flag=${__opt_is_flag[$canon_name]}
			local default_value=${__opt_default_val[$canon_name]}
			echo -n "     "
			__getoptz_usage_option "$canon_name"
			local alias_name; for alias_name in $alias_names; do
				echo -n ', '
				__getoptz_usage_option "$alias_name"
			done
			if [[ $default_value && ! $is_flag ]]; then echo -n "    [Default value: $default_value]"; fi
			echo
			if [[ $help_string ]]; then echo -e "${help_string}\n" | awk '{ print "            " $0 }'; fi
		done
	done

	IFS=$old_ifs
	exit "$exit_code"
}

# Print to standard out: "--option option" or "-o option"
function __getoptz_usage_option {
	local option_name=$1
	local canon_name=${__opt_canon_name["$option_name"]}
	local is_flag=${__opt_is_flag[$canon_name]}
	if [[ ${#option_name} -eq 1 ]]; then printf -- "-$option_name"
	else printf -- "--$option_name"
	fi
	[[ $is_flag ]] || echo -ne " $u$canon_name$n"
}

# Display message in case of programmer error
function __getoptz_die {
	local msg=$1
	echo -e "$msg" >&2
	exit 1
}

# Display message in case of user error
function __getoptz_invalid_args {
	local msg=$1
	echo "$msg" >&2
	getoptz_usage 1
}

function getoptz_configure {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--help) __getoptz_conf[help]="$2";shift 2;;
			*) __getoptz_die "getoptz_configure: unknown option: $1!"
		esac
	done
}

function add_opt {
  local syntax_msg="Syntax: add_opt OPTION_NAME[:] [ALIAS]... [--help HELP_STRING] [--dest DEST_VAR] [--default DEFAULT_VALUE]"
	[[ $# -ge 1 ]] || echo -e "error in add_opt!\n$syntax_msg"
	
	# parse positional args
	local canon_name=${1%:}
	local is_flag=1
	if [[ ${1: -1} == ':' ]]; then is_flag=''; fi
	shift
	
	local alias_name=''
	while [[ $# -gt 0 && ${1:-} != --* ]]; do
		# alias name is provided
		alias_name=$1
		[[ ${#alias_name} -ge 1 ]] || __getoptz_die "add_opt: SHORT_OPTION must be at least 1 character long!\n$syntax_msg"
		__opt_canon_name[$alias_name]=$canon_name
		__opt_alias_name[$canon_name]+=" $alias_name"
		shift
	done

	# parse options
	local default_value='' help_string='' dest=$canon_name is_multi='' help_group="$__DEFAULT_HELP_GROUP"
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dest) dest=$2; shift 2;;
			--help) help_string=$2; shift 2;;
			--multi) is_multi=1; shift 1;;
			--default) default_value=$2; shift 2;;
			--group) help_group=$2; shift 2;;
			*) __getoptz_die "add_opt: unknown argument: $1!\n$syntax_msg";;
		esac
	done

	[[ ($is_multi && !$default_value) || !$is_multi ]] || __getoptz_die "add_opt: cannot set a default value for multi-valued options."

	# check dest for special characters
	[[ $dest =~ ^[[:alnum:]_]+$ ]] || __getoptz_die "add_opt: Invalid identifier: $dest!\n$syntax_msg"

	__opt_canon_name[$canon_name]=$canon_name
	__opt_is_flag[$canon_name]=$is_flag
	__opt_is_multi[$canon_name]=$is_multi
	__opt_default_val[$canon_name]="$default_value"
	__opt_help[$canon_name]="$help_string"
	__opt_help_group[$canon_name]="$help_group"
	[[ $help_group == $__DEFAULT_HELP_GROUP ]] || __all_help_groups["$help_group"]=1
	__opt_dest[$canon_name]="$dest"

	# assign default value to option:
	#  - options already set by the caller, with no default value, are left unchanged.
	if [[ !${!canon_name+x} || $default_value ]]; then
		if [[ $is_multi ]]; then
			__getoptz_array_set_empty "$canon_name"
		else
			__getoptz_eval_opt "$canon_name" "$default_value"
		fi
	fi
}

# Syntax:
#   add_arg ARG_NAME [1 | '?' | '+' | '*' ] [--help HELP_STRING] [--default DEFAULT_VALUE]
function add_arg {
  local syntax_msg="Syntax: add_arg ARG_NAME [1 | '?' | '+' | '*' ] [--help HELP_STRING] [--default DEFAULT_VALUE]"
	[[ $# -ge 1 ]] || __getoptz_die "add_arg: at least 1 argument expected!\n$syntax_msg"
	# parse positional args
	local arg_name=$1; shift

	local multiplicity=1
	if [[ $# -gt 0 && ${1:-} != --* ]]; then
		multiplicity=$1; shift
		[[ $multiplicity == @(1|'?'|'+'|'*') ]] || __getoptz_die "add_arg: Invalid multiplicity for argument $arg_name: $multiplicity!\n$syntax_msg"
	fi

	# parse options	
	local default_value='' help_string=''
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--help) help_string=$2; shift 2;;
			--default) default_value=$2; shift 2;;
			*) __getoptz_die "add_arg: unknown argument: $1!\n$syntax_msg";;
		esac
	done

	# validate: default value set => multiplicity is '1' or '?'
	if [[ $default_value ]]; then
		if [[ $multiplicity == 1 ]]; then
			# to simplify the validation of arguments, we change the requested multiplicity because this is what was intented by the user.
			multiplicity='?'
		elif [[ $multiplicity == '*' || $multiplicity == '+' ]]; then
			__getoptz_die "add_arg: for argument $arg_name, cannot set multiplicity to '$multiplicity' with a default value. Either remove the default value, or change the multiplicity to '?'."
		fi
	fi


	# validate multiplicity
	if [[ ${#__arg_name[@]} -gt 0 ]]; then
		local multiplicity_of_last=${__arg_multiplicity[@]: -1}
		[[ $multiplicity_of_last == 1 || ( $multiplicity_of_last == '?' && $multiplicity == '?' ) ]] || __getoptz_die "add_arg: invalid multiplicity for argument $arg_name. Cannot have previous arg with multiplicity '$multiplicity_of_last' and $arg_name with multiplicity '$multiplicity' !\n$syntax_msg"
	fi
	__arg_name+=("$arg_name")
	__arg_default_val+=("$default_value")
	__arg_help+=("$help_string")
	__arg_multiplicity+=("$multiplicity")
	[[ $multiplicity == @('+'|'*') ]] || __getoptz_assign_variable "$arg_name" "$default_value"
}

function getoptz_print_report {
	echo "Args:"
	if [[ ${#ARG[@]} -gt 0 ]]; then
		local arg; for arg in "${ARG[@]}"; do
			echo "  $arg"
		done
	fi

	echo "Options:"
	local key; for key in "${!OPT[@]}"; do
		echo "  $key=${OPT[$key]}"
	done
}

# map of "option canonical name" --> "option value"
declare -A OPT
declare -a ARG=()
declare -a __arg_name=() __arg_multiplicity __arg_default_val __arg_help
# map of "option name (long or short)" --> "option canonical name"
declare -A __opt_canon_name
# map of "option canonical name" --> "aliases, separated with spaces".
declare -A __opt_alias_name
# map of "option canonical name" --> 1 or ''
declare -A __opt_is_flag
# map of "option canonical name" --> 1 or ''
declare -A __opt_is_multi
# map of "option canonical name" --> "option default value"
declare -A __opt_default_val
# map of "option canonical name" --> "option help string"
declare -A __opt_help
# map of "option canonical namae" --> "option help group"
declare -A __opt_help_group
# set of all help groups (implemented as an associative array)
declare -A __all_help_groups
# map of "option canonical name" --> "destination variable name"
declare -A __opt_dest
# map of "key" --> "value". Allowed keys: "help" only.
declare -A __getoptz_conf
# Default help group name
declare -r __DEFAULT_HELP_GROUP="Options"
