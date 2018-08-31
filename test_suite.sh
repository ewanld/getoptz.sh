#! /usr/bin/env bash
set -o nounset
set -o errexit

function main {
	if [[ $test_name == ALL ]]; then
		run_all_tests
	else
		run_test "$test_name"
	fi
}

# tests ending with '_fail' are expected to exit with a nonzero status.
function run_all_tests {
	# test arguments
	expect_exit 0 "$script_path" 'nil_with_nil'
	expect_exit 1 "$script_path" 'nil_with_1_fail'
	expect_exit 1 "$script_path" 'a_with_nil_fail'
	expect_exit 0 "$script_path" 'a_with_1'
	expect_exit 1 "$script_path" 'a_with_12_fail'
	expect_exit 0 "$script_path" 'a?_with_nil'
	expect_exit 0 "$script_path" 'a?_with_1'
	expect_exit 1 "$script_path" 'a?_with_12_fail'
	expect_exit 1 "$script_path" 'ab_with_1_fail'
	expect_exit 0 "$script_path" 'ab_with_12'
	expect_exit 1 "$script_path" 'ab_with_123_fail'
	expect_exit 0 "$script_path" 'a?b?_with_nil'
	expect_exit 0 "$script_path" 'a?b?_with_1'
	expect_exit 0 "$script_path" 'a?b?_with_12'
	expect_exit 1 "$script_path" 'a?b?_with_123_fail'
	expect_exit 1 "$script_path" 'ab?_with_nil_fail'
	expect_exit 0 "$script_path" 'ab?_with_1'
	expect_exit 0 "$script_path" 'ab?_with_12'
	expect_exit 1 "$script_path" 'ab?_123_fail'
	expect_exit 1 "$script_path" 'a?b_fail'
	expect_exit 0 "$script_path" 'a*_with_nil'
	expect_exit 0 "$script_path" 'a*_with_1'
	expect_exit 0 "$script_path" 'a*_with_12'
	expect_exit 1 "$script_path" 'ab*_wth_nil_fail'
	expect_exit 1 "$script_path" 'a*b_fail'
	expect_exit 1 "$script_path" 'a*b*_fail'
	expect_exit 1 "$script_path" 'a*b+_fail'
	expect_exit 1 "$script_path" 'a+_with_nil_fail'
	expect_exit 0 "$script_path" 'a+_with_1'
	expect_exit 0 "$script_path" 'a+_with_12'
	expect_exit 1 "$script_path" 'a+b+_fail'
	expect_exit 0 "$script_path" 'ab+_with_12'
	expect_exit 0 "$script_path" 'ab+_with_123'

	# test special chars in argument values
	expect_exit 0 "$script_path" 'a_with_space'
	expect_exit 0 "$script_path" 'a_with_empty_string'
	expect_exit 0 "$script_path" 'a_with_special_chars'
	expect_exit 0 "$script_path" 'a_with_newline'
	expect_exit 0 "$script_path" 'a_with_dash'
	expect_exit 0 "$script_path" 'a+_with_dash'

	# test options (option name and value separated with a space)
	expect_exit 0 "$script_path" '--opt:_with_--opt_2'
	expect_exit 0 "$script_path" '--opt_with_--opt'
	expect_exit 1 "$script_path" '--opt:_with_--opt_fail'
	expect_exit 1 "$script_path" '--opt_with_--opt_1_fail'
	expect_exit 0 "$script_path" '-o:_with_-o_2'
	expect_exit 0 "$script_path" '-o_with_-o'
	expect_exit 1 "$script_path" '-o:_with_-o_fail'
	expect_exit 1 "$script_path" '-o_with_-o_2_fail'

	# test alternative ways of setting options (--opt=2 or --opt:2 or -o2)
	expect_exit 0 "$script_path" '--opt:_with_--opt=2'
	expect_exit 0 "$script_path" '--opt:_with_--opt:2'
	expect_exit 0 "$script_path" '-o:_with_-o2'
}

function run_test {
	local -l test_name=$1; shift
	
	case "$test_name" in
	'nil_with_nil') getoptz_parse;;
	'nil_with_1_fail') getoptz_parse 1;;
	'0_arg_2_arg_fail') getoptz_parse 1 2;;
	'a_with_nil_fail')
		add_arg a
		getoptz_parse
		;;
	'a_with_1')
		add_arg a
		getoptz_parse 1
		expect_equals "$a" 1
		;;
	'a_with_12_fail')
		add_arg a
		getoptz_parse 1 2
		;;
	'a?_with_nil')
		add_arg a '?'
		getoptz_parse
		expect_equals "$a" ''
		;;
	'a?_with_1')
		add_arg a '?'
		getoptz_parse 1
		expect_equals "$a" 1
		;;
	'a?_with_12_fail')
		add_arg a '?'
		getoptz_parse 1 2
		;;
	'ab_with_1_fail')
		add_arg a
		add_arg b
		getoptz_parse 1
		;;
	'ab_with_12')
		add_arg a
		add_arg b
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'ab_with_123_fail')
		add_arg a
		add_arg b
		getoptz_parse 1 2 3
		;;
	'a?b?_with_nil')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse
		expect_equals "$a" ""
		expect_equals "$b" ""
		;;
	'a?b?_with_1')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1
		expect_equals "$a" 1
		expect_equals "$b" ""
		;;
	'a?b?_with_12')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'a?b?_with_123_fail')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1 2 3
		;;
	'ab?_with_nil_fail')
		add_arg a
		add_arg b '?'
		getoptz_parse
		;;
	'ab?_with_1')
		add_arg a
		add_arg b '?'
		getoptz_parse 1
		expect_equals "$a" 1
		expect_equals "$b" ""
		;;
	'ab?_with_12')
		add_arg a
		add_arg b '?'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'ab?_with_123_fail')
		add_arg a
		add_arg b '?'
		getoptz_parse 1 2 3
		;;
	'a?b_fail')
		add_arg a '?'
		add_arg b
		;;
	'a*_with_nil')
		add_arg a '*'
		getoptz_parse
		;;
	'a*_with_1')
		add_arg a '*'
		getoptz_parse 1
		expect_equals "${a[0]}" 1
		;;
	'a*_with_12')
		add_arg a '*'
		getoptz_parse 1 2
		expect_equals "${a[0]}" 1
		expect_equals "${a[1]}" 2
		;;
	'ab*_with_nil_fail')
		add_arg a
		add_arg b '*'
		getoptz_parse
		;;
	'a*b_fail')
		add_arg a '*'
		add_arg b
		;;
	'a*b*_fail')
		add_arg a '*'
		add_arg b '*'
		;;
	'a*b+_fail')
		add_arg a '*'
		add_arg b '+'
		;;
	'a+_with_nil_fail')
		add_arg a '+'
		getoptz_parse
		;;
	'a+_with_1')
		add_arg a '+'
		getoptz_parse 1
		expect_equals ${#a[@]} 1
		expect_equals "${a[0]}" 1
		;;
	'a+_with_12')
		add_arg a '+'
		getoptz_parse 1 2
		expect_equals ${#a[@]} 2
		expect_equals "${a[0]}" 1
		expect_equals "${a[1]}" 2
		;;
	'a+b+_fail')
		add_arg a '+'
		add_arg b '+'
		;;
	'ab+_with_12')
		add_arg a
		add_arg b '+'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "${#b[@]}" 1
		expect_equals "${b[0]}" 2
		;;
	'ab+_with_123')
		add_arg a
		add_arg b '+'
		getoptz_parse 1 2 3
		expect_equals "$a" 1
		expect_equals "${#b[@]}" 2
		expect_equals "${b[0]}" 2
		expect_equals "${b[1]}" 3
		;;
	'a_with_space')
		add_arg a
		getoptz_parse ' '
		expect_equals "$a" ' '
		;;
	'a_with_empty_string')
		add_arg a
		getoptz_parse ''
		expect_equals "$a" ''
		;;
	'a_with_special_chars')
		add_arg a
		getoptz_parse '$*'
		expect_equals "$a" '$*'
		;;
	'a_with_newline')
		add_arg a
		getoptz_parse 1$'\n'2
		expect_equals "$a" 1$'\n'2
		;;
	'a_with_dash')
		add_arg a
		getoptz_parse -- --
		expect_equals "$a" --
		;;
	'a+_with_dash')
		add_arg a +
		getoptz_parse --  1 -o --opt
		expect_equals "${#a[@]}" 3
		expect_equals "${a[0]}" 1
		expect_equals "${a[1]}" -o
		expect_equals "${a[2]}" --opt
		;;
	'--opt:_with_--opt_2')
		add_opt opt:
		getoptz_parse --opt 1
		expect_equals "$opt" 1
		;;
	'--opt_with_--opt')
		add_opt opt
		getoptz_parse --opt
		expect_equals "$opt" 1
		;;
	'--opt:_with_--opt_fail')
		add_opt opt:
		getoptz_parse --opt
		;;
	'--opt_with_--opt_2_fail')
		add_opt opt
		getoptz_parse --opt 1
		;;
	'-o_with_-o')
		add_opt opt o
		getoptz_parse -o
		expect_equals "$opt" 1
		;;
	'-o:_with_-o_2')
		add_opt opt: o
		getoptz_parse -o 2
		expect_equals "$opt" 2
		;;
	'-o:_with_-o_fail')
		add_opt opt: o
		getoptz_parse -o
		;;
	'-o_with_-o_2_fail')
		add_opt opt o
		getoptz_parse -o 2
		;;
	'--opt:_with_--opt=2')
		add_opt opt: o
		getoptz_parse --opt=2
		;;
	'--opt:_with_--opt:2')
		add_opt opt: o
		getoptz_parse --opt:2
		;;
	'-o:_with_-o2')
		add_opt opt: o
		getoptz_parse -o2
		;;
	*)
		_die "unknown test: $test_name!"
		;;
	esac
}

function parse_args {
	if [[ $# -eq 0 ]]; then
		test_name=ALL
	else
		test_name=$1; shift
	fi
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# utility functions

function expect_exit {
	local expected=$1; shift
	set +o errexit
	echo -n "Running: $@... "
	if [[ $expected -eq 0 ]]; then
		"$@" > /dev/null
	else
		"$@" >/dev/null 2>&1
	fi
	local exit_code=$?
	set -o errexit
	if [[ $exit_code -eq $expected ]]; then
		_log "${esc_green}OK${esc_normal}"
	else
		 _die "Expected exit code: $expected, got: $exit_code!"
	fi
}

function expect_equals {
	local value1=$1; shift
	local values=("$@")
	local v; for v in "${values[@]}"; do
		[[ $v == $value1 ]] || _die "Assertion error: $v != $value1!"
	done
}

function _die {
	echo "$@" >&2
	exit 1
}

function _log {
	echo -e "$@" >&2
}

esc_bold='\033[1m'
esc_underlined='\033[4m'
esc_normal='\033[0m'
esc_blue='\033[34;1m'
esc_red='\033[31;1m'
esc_green='\033[32;1m'

#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

script_dir=$(dirname "$0")
script_path=$(readlink -f "$0")

. "$script_dir/getoptz.sh"
parse_args "$@"
main
