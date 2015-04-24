#! /bin/bash
# ------------------------------------------------------------------------------
# Library to parse command line arguments.
# Works with Bash version >= 4.
# 
# functions/variables starting with __ are internal functions.
# Other functions/variables are part of the public API.
# 
# Sample usage:
#   add_opt output_dir: d                  --help "Output directory. The colon means a value is mandatory"
#   add_arg file                           --help "Input file"
#   getoptz_configure                      --help "Description of my script."
#   getoptz_parse "$@"
#  
# Examples of valid arguments:
#   ./my_script --dir /tmp /tmp/myfile.txt
#   ./my_script -d/tmp /tmp/myfile.txt
#   ./my_script /tmp/myfile.txt

# Examples of invalid arguments:
#   ./my_script --dir /tmp              # argument 'file' is missing!
#   ./my_script /tmp/myfile.txt 2       # only 1 argument expected, got 2!
# ------------------------------------------------------------------------------

function getoptz_parse {
	while [[ $# -gt 0 ]]; do
		if [[ $1 == '--' ]]; then
			shift
			ARG+=("$@")
			break

		elif [[ $1 == @(-h|--help) ]]; then
			getoptz_usage
			exit 0

		# FIXME handle case where the first option (e.g 'x' in -xvf) is not a flag -> flags should not be expanded
		#elif [[ $1 =~ ^-([[:alnum:]]{2,}) ]]; then
		#	# case -xvf
		#	local opts=${BASH_REMATCH[1]}
		#	echo "-xvf"
		#	opts_expanded=$(echo $opts | sed 's/./-& /g')
		#	shift
		#	set -- $opts_expanded "$@"
	
		elif [[ $1 =~ ^(-[[:alnum:]])[=:]?(.+) || \
			    $1 =~ ^(--[[:alnum:]_-]{2,})[=:](.+) ]]; then
			# case -v=1 or -v1 or -v:1 or --verbose=1 or --verbose:1
			local option="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[2]}"
			set -- "$@" $option "$value"
			shift

		elif [[ $1 =~ ^-([[:alnum:]]) || \
			    $1 =~ ^--([[:alnum:]_-]{2,}) ]]; then
			# case -v 1 or -v or --verbose or --verbose 1
			local option="${BASH_REMATCH[1]}"
			local long_name=${__opt_long_name[$option]:-}
			[[ $long_name ]] || __getoptz_invalid_args "unknown option: $option!"
			local is_flag=${__opt_is_flag[$long_name]:-}
			shift
			[[ $is_flag || $# -ne 0 ]] || __getoptz_invalid_args "Value expected for option $option!"	
			if [[ $is_flag ]]; then
				value=1
			else
				value="${1:-}"
				shift
			fi
			__getoptz_eval_opt $long_name "$value"
			
		else
			ARG+=("$1")
			shift
		fi
	done
	
	__getoptz_validate_args
	__getoptz_eval_args
	#unset __opt_long_name __opt_is_flag __opt_default_val __opt_help __opt_dest
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

function __getoptz_eval_opt {
	local __opt_long_name=$1
	local __value=$2
	OPT[$__opt_long_name]=$__value
	local __opt_dest_var=${__opt_dest[$__opt_long_name]}
	if [[ $__opt_dest_var ]]; then
		__getoptz_assign_variable "$__opt_dest_var" "$__value"
	fi
}

function getoptz_usage {
	local script_name=$(basename $0)
	local u='\033[4m'
	local n='\033[0m'

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
		echo -e "$help_string\n" | sed 's/^/    /'
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
			if [[ $help_string ]]; then echo -e "$help_string" | sed 's/^/            /'; fi
			echo
		done
	fi

	# options section
	echo -e "Options:
     -h, --help
            Display this help and exit.
"
	local key; for key in "${!__opt_long_name[@]}"; do
		if [[ ${#key} -eq 1 ]]; then
			local long_name=${__opt_long_name[$key]}
			local help_string=${__opt_help[$long_name]}
			local is_flag=${__opt_is_flag[$long_name]}
			local default_value=${__opt_default_val[$long_name]}
			echo -n "     -$key"
			[[ $is_flag ]] || echo -ne " $u$long_name$n"
			echo -n ", --$long_name"
			[[ $is_flag ]] || echo -ne "=$u$long_name$n"
			if [[ $default_value && ! $is_flag ]]; then echo -n "    [Default value: $default_value]"; fi
			echo
			if [[ $help_string ]]; then echo -e " $help_string\n" | sed 's/^/           /'; fi
		fi
	done

	exit 1
}

# Display message in case of programmer error
function __getoptz_die {
	local msg=$1
	echo "$msg"
	exit 1
}

# Display message in case of user error
function __getoptz_invalid_args {
	local msg=$1
	echo "$msg"
	getoptz_usage
	exit 1
}

function getoptz_configure {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--help) __getoptz_conf[help]="$2";shift 2;;
			*) __getoptz_die "getoptz_configure: unknown option: $1!"
		esac
	done
}

# Syntax:
#   add_opt LONG_NAME[:] [SHORT_NAME] [--help HELP_STRING] [--dest DEST_VAR] [--default DEFAULT_VALUE]
function add_opt {
	[[ $# -ge 1 ]] || echo "error in add_opt!"
	
	# parse positional args
	local long_name=${1%:}
	local is_flag=1
	if [[ ${1: -1} == ':' ]]; then is_flag=''; fi
	shift

	if [[ ${1:-} != --* ]]; then
		# short name is provided
		local short_name=$1
		[[ ${#short_name} -eq 1 ]] || __getoptz_die "add_opt: SHORT_OPTION must be 1 character long!"
		shift
	fi

	# parse options
	local default_value='' help_string='' dest=$long_name
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--dest) dest=$2; shift 2;;
			--help) help_string=$2; shift 2;;
			--default) default_value=$2; shift 2;;
			*) __getoptz_die "add_opt: unknown argument: $1!";;
		esac
	done
	
	# check dest for special characters
	[[ $dest =~ ^[[:alnum:]_]+$ ]] || __getoptz_die "add_opt: Invalid identifier: $dest!"

	if [[ ${short_name:-} ]]; then __opt_long_name[$short_name]=$long_name; fi
	__opt_long_name[$long_name]=$long_name
	__opt_is_flag[$long_name]=$is_flag
	__opt_default_val[$long_name]="$default_value"
	__opt_help[$long_name]="$help_string"
	__opt_dest[$long_name]="$dest"

	__getoptz_eval_opt $long_name "$default_value"
}

# Syntax:
#   add_arg ARG_NAME [1 | '?' | '+' | '*' ] [--help HELP_STRING] [--default DEFAULT_VALUE]
function add_arg {
	[[ $# -ge 1 ]] || __getoptz_die "add_arg: at least 1 argument expected!"
	# parse positional args
	local arg_name=$1; shift

	local multiplicity=1
	if [[ $# -gt 0 && ${1:-} != --* ]]; then
		multiplicity=$1; shift
		[[ $multiplicity == @(1|'?'|'+'|'*') ]] || __getoptz_die "add_arg: Invalid multiplicity: $multiplicity!"
	fi

	# validate multiplicity
	if [[ ${#__arg_name[@]} -gt 0 ]]; then
		local multiplicity_of_last=${__arg_multiplicity[@]: -1}
		[[ $multiplicity_of_last == 1 || ( $multiplicity_of_last == '?' && $multiplicity == '?' ) ]] || __getoptz_die "add_arg: cannot have arg n-1 with multiplicity '$multiplicity_of_last' and arg n with multiplicity '$multiplicity' !"
	fi

	# parse options	
	local default_value='' help_string=''
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--help) help_string=$2; shift 2;;
			--default) default_value=$2; shift 2;;
			*) __getoptz_die "add_arg: unknown argument: $1!";;
		esac
	done

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

declare -A OPT
declare -a ARG=()
declare -a __arg_name __arg_multiplicity __arg_default_val __arg_help
declare -A __opt_long_name __opt_is_flag __opt_default_val __opt_help __opt_dest
declare -A __getoptz_conf

