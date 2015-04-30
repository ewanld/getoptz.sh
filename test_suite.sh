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

function run_all_tests {
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
