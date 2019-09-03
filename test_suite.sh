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

# tests ending with ' expected fail' are expected to exit with a nonzero status.
function run_all_tests {
	# test arguments
	run_test_isolated 'nil with nil'
	run_test_isolated 'nil with 1 expected fail'
	run_test_isolated 'nil with 1 2 expected fail'
	run_test_isolated 'a with nil expected fail'
	run_test_isolated 'a with 1'
	run_test_isolated 'a with 1 2 expected fail'
	run_test_isolated 'a? with nil'
	run_test_isolated 'a? with 1'
	run_test_isolated 'a? with 1 2 expected fail'
	run_test_isolated 'ab with 1 expected fail'
	run_test_isolated 'ab with 1 2'
	run_test_isolated 'ab with 1 2 3 expected fail'
	run_test_isolated 'a?b? with nil'
	run_test_isolated 'a?b? with 1'
	run_test_isolated 'a?b? with 1 2'
	run_test_isolated 'a?b? with 1 2 3 expected fail'
	run_test_isolated 'ab? with nil expected fail'
	run_test_isolated 'ab? with 1'
	run_test_isolated 'ab? with 1 2'
	run_test_isolated 'ab? with 1 2 3 expected fail'
	run_test_isolated 'a?b expected fail'
	run_test_isolated 'a* with nil'
	run_test_isolated 'a* with 1'
	run_test_isolated 'a* with 1 2'
	run_test_isolated 'ab* with nil expected fail'
	run_test_isolated 'a*b expected fail'
	run_test_isolated 'a*b* expected fail'
	run_test_isolated 'a*b+ expected fail'
	run_test_isolated 'a+ with nil expected fail'
	run_test_isolated 'a+ with 1'
	run_test_isolated 'a+ with 1 2'
	run_test_isolated 'a+b+ expected fail'
	run_test_isolated 'ab+ with 1 2'
	run_test_isolated 'ab+ with 1 2 3'

	# test special chars in argument values
	run_test_isolated 'a with space'
	run_test_isolated 'a with empty_string'
	run_test_isolated 'a with special_chars'
	run_test_isolated 'a with newline'
	run_test_isolated 'a with dash'
	run_test_isolated 'a+ with dash'

	# test options (option name and value separated with a space)
	run_test_isolated '--opt: with --opt_2'
	run_test_isolated '--opt with --opt'
	run_test_isolated '--opt: with --opt expected fail'
	run_test_isolated '--opt with --opt_1 expected fail'
	run_test_isolated '-o: with -o_2'
	run_test_isolated '-o with -o'
	run_test_isolated '-o: with -o expected fail'
	run_test_isolated '-o with -o_2 expected fail'
	run_test_isolated '-opq'

	# test alternative ways of setting options (--opt=2 or --opt:2 or -o2)
	run_test_isolated '--opt: with --opt=2'
	run_test_isolated '--opt: with --opt:2'
	run_test_isolated '-o: with -o2'

	# test option aliases
	run_test_isolated '--opt: with --optalias=2'
	run_test_isolated '-o: with --optalias2=2'
	run_test_isolated '-o: with -z=2'
}

function run_test {
	local -l test_name=$1; shift
	
	case "$test_name" in
	'nil with nil') getoptz_parse;;
	'nil with 1 expected fail') getoptz_parse 1;;
	'nil with 1 2 expected fail') getoptz_parse 1 2;;
	'a with nil expected fail')
		add_arg a
		getoptz_parse
		;;
	'a with 1')
		add_arg a
		getoptz_parse 1
		expect_equals "$a" 1
		;;
	'a with 1 2 expected fail')
		add_arg a
		getoptz_parse 1 2
		;;
	'a? with nil')
		add_arg a '?'
		getoptz_parse
		expect_equals "$a" ''
		;;
	'a? with 1')
		add_arg a '?'
		getoptz_parse 1
		expect_equals "$a" 1
		;;
	'a? with 1 2 expected fail')
		add_arg a '?'
		getoptz_parse 1 2
		;;
	'ab with 1 expected fail')
		add_arg a
		add_arg b
		getoptz_parse 1
		;;
	'ab with 1 2')
		add_arg a
		add_arg b
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'ab with 1 2 3 expected fail')
		add_arg a
		add_arg b
		getoptz_parse 1 2 3
		;;
	'a?b? with nil')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse
		expect_equals "$a" ""
		expect_equals "$b" ""
		;;
	'a?b? with 1')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1
		expect_equals "$a" 1
		expect_equals "$b" ""
		;;
	'a?b? with 1 2')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'a?b? with 1 2 3 expected fail')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1 2 3
		;;
	'ab? with nil expected fail')
		add_arg a
		add_arg b '?'
		getoptz_parse
		;;
	'ab? with 1')
		add_arg a
		add_arg b '?'
		getoptz_parse 1
		expect_equals "$a" 1
		expect_equals "$b" ""
		;;
	'ab? with 1 2')
		add_arg a
		add_arg b '?'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'ab? with 1 2 3 expected fail')
		add_arg a
		add_arg b '?'
		getoptz_parse 1 2 3
		;;
	'a?b expected fail')
		add_arg a '?'
		add_arg b
		;;
	'a* with nil')
		add_arg a '*'
		getoptz_parse
		;;
	'a* with 1')
		add_arg a '*'
		getoptz_parse 1
		expect_equals "${a[0]}" 1
		;;
	'a* with 1 2')
		add_arg a '*'
		getoptz_parse 1 2
		expect_equals "${a[0]}" 1
		expect_equals "${a[1]}" 2
		;;
	'ab* with nil expected fail')
		add_arg a
		add_arg b '*'
		getoptz_parse
		;;
	'a*b expected fail')
		add_arg a '*'
		add_arg b
		;;
	'a*b* expected fail')
		add_arg a '*'
		add_arg b '*'
		;;
	'a*b+ expected fail')
		add_arg a '*'
		add_arg b '+'
		;;
	'a+ with nil expected fail')
		add_arg a '+'
		getoptz_parse
		;;
	'a+ with 1')
		add_arg a '+'
		getoptz_parse 1
		expect_equals ${#a[@]} 1
		expect_equals "${a[0]}" 1
		;;
	'a+ with 1 2')
		add_arg a '+'
		getoptz_parse 1 2
		expect_equals ${#a[@]} 2
		expect_equals "${a[0]}" 1
		expect_equals "${a[1]}" 2
		;;
	'a+b+ expected fail')
		add_arg a '+'
		add_arg b '+'
		;;
	'ab+ with 1 2')
		add_arg a
		add_arg b '+'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "${#b[@]}" 1
		expect_equals "${b[0]}" 2
		;;
	'ab+ with 1 2 3')
		add_arg a
		add_arg b '+'
		getoptz_parse 1 2 3
		expect_equals "$a" 1
		expect_equals "${#b[@]}" 2
		expect_equals "${b[0]}" 2
		expect_equals "${b[1]}" 3
		;;
	'a with space')
		add_arg a
		getoptz_parse ' '
		expect_equals "$a" ' '
		;;
	'a with empty_string')
		add_arg a
		getoptz_parse ''
		expect_equals "$a" ''
		;;
	'a with special_chars')
		add_arg a
		getoptz_parse '$*'
		expect_equals "$a" '$*'
		;;
	'a with newline')
		add_arg a
		getoptz_parse 1$'\n'2
		expect_equals "$a" 1$'\n'2
		;;
	'a with dash')
		add_arg a
		getoptz_parse -- --
		expect_equals "$a" --
		;;
	'a+ with dash')
		add_arg a +
		getoptz_parse --  1 -o --opt
		expect_equals "${#a[@]}" 3
		expect_equals "${a[0]}" 1
		expect_equals "${a[1]}" -o
		expect_equals "${a[2]}" --opt
		;;
	'--opt: with --opt_2')
		add_opt opt:
		getoptz_parse --opt 1
		expect_equals "$opt" 1
		;;
	'--opt with --opt')
		add_opt opt
		getoptz_parse --opt
		expect_equals "$opt" 1
		;;
	'--opt: with --opt expected fail')
		add_opt opt:
		getoptz_parse --opt
		;;
	'--opt with --opt_1 expected fail')
		add_opt opt
		getoptz_parse --opt 1
		;;
	'-o with -o')
		add_opt opt o
		getoptz_parse -o
		expect_equals "$opt" 1
		;;
	'-o: with -o_2')
		add_opt opt: o
		getoptz_parse -o 2
		expect_equals "$opt" 2
		;;
	'-o: with -o expected fail')
		add_opt opt: o
		getoptz_parse -o
		;;
	'-o with -o_2 expected fail')
		add_opt opt o
		getoptz_parse -o 2
		;;
	'--opt: with --opt=2')
		add_opt opt: o
		getoptz_parse --opt=2
		expect_equals "$opt" 2
		;;
	'--opt: with --opt:2')
		add_opt opt: o
		getoptz_parse --opt:2
		expect_equals "$opt" 2
		;;
	'-o: with -o2')
		add_opt opt: o
		getoptz_parse -o2
		expect_equals "$opt" 2
		;;
	'-opq')
		add_opt opt1 o
		add_opt opt2 p
		add_opt opt3 q
		add_opt opt4 r
		getoptz_parse -opq
		expect_equals "$opt1" 1
		expect_equals "$opt2" 1
		expect_equals "$opt3" 1
		expect_equals "$opt4" ''
		;;
	'--opt: with --optalias=2')
		add_opt opt: optalias
		getoptz_parse --optalias=2
		expect_equals "$opt" 2
		;;
	'-o: with --optalias2=2')
		add_opt o: optalias optalias2 z
		getoptz_parse --optalias2=2
		expect_equals "$o" 2
		;;
	'-o: with -z=2')
		add_opt o: optalias optalias2 z
		getoptz_parse -z=2
		expect_equals "$o" 2
		;;
	'-o:--default1 with nil')
		add_opt o: --default 2
		getoptz_parse
		expect_equals "$o" 2
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

function run_test_isolated {
	local test_name=$1
	if [[ $test_name == *"expected fail" ]]; then expected=1
	else expected=0
	fi
	set +o errexit
	if [[ $expected -eq 0 ]]; then
		"$script_path" "$test_name" > /dev/null
	else
		"$script_path" "$test_name" >/dev/null 2>&1
	fi
	local exit_code=$?
	set -o errexit
	echo -n "Executing test: "	
	printf '%-40s' "$test_name"
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
	exit 2
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
