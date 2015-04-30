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
	expect_exit 0 "$script_path" '0_arg_0_arg'
	expect_exit 1 "$script_path" '0_arg_1_arg_fail'
	expect_exit 1 "$script_path" '1_arg_0_arg_fail'
	expect_exit 0 "$script_path" '1_arg_1_arg'
	expect_exit 1 "$script_path" '1_arg_2_arg_fail'
	expect_exit 0 "$script_path" '1_arg_optional_0_arg'
	expect_exit 0 "$script_path" '1_arg_optional_1_arg'
	expect_exit 1 "$script_path" '1_arg_optional_2_arg_fail'
	expect_exit 1 "$script_path" '2_arg_1_arg_fail'
	expect_exit 0 "$script_path" '2_arg_2_arg'
	expect_exit 1 "$script_path" '2_arg_3_arg_fail'
	expect_exit 0 "$script_path" '2_arg_optional_0_arg'
	expect_exit 0 "$script_path" '2_arg_optional_1_arg'
	expect_exit 0 "$script_path" '2_arg_optional_2_arg'
	expect_exit 1 "$script_path" '2_arg_optional_3_arg_fail'
	expect_exit 1 "$script_path" '2_arg_optional_3_arg_fail'
	expect_exit 1 "$script_path" '1_arg_1_arg_optional_0_arg_fail'
	expect_exit 0 "$script_path" '1_arg_1_arg_optional_1_arg'
	expect_exit 0 "$script_path" '1_arg_1_arg_optional_2_arg'
	expect_exit 1 "$script_path" '1_arg_1_arg_optional_3_arg_fail'
	expect_exit 1 "$script_path" '1_arg_optional_1_arg_fail'
	expect_exit 0 "$script_path" '1_arg*_0_arg'
}

function run_test {
	local -l test_name=$1; shift
	
	case "$test_name" in
	'0_arg_0_arg') getoptz_parse;;
	'0_arg_1_arg_fail') getoptz_parse 1;;
	'0_arg_2_arg_fail') getoptz_parse 1 2;;
	'1_arg_0_arg_fail')
		add_arg a
		getoptz_parse
		;;
	'1_arg_1_arg')
		add_arg a
		getoptz_parse 1
		expect_equals "$a" 1
		;;
	'1_arg_2_arg_fail')
		add_arg a
		getoptz_parse 1 2
		;;
	'1_arg_optional_0_arg')
		add_arg a '?'
		getoptz_parse
		expect_equals "$a" ''
		;;
	'1_arg_optional_1_arg')
		add_arg a '?'
		getoptz_parse 1
		expect_equals "$a" 1
		;;
	'1_arg_optional_2_arg_fail')
		add_arg a '?'
		getoptz_parse 1 2
		;;
	'2_arg_1_arg_fail')
		add_arg a
		add_arg b
		getoptz_parse 1
		;;
	'2_arg_2_arg')
		add_arg a
		add_arg b
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'2_arg_3_arg_fail')
		add_arg a
		add_arg b
		getoptz_parse 1 2 3
		;;
	'2_arg_optional_0_arg')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse
		expect_equals "$a" ""
		expect_equals "$b" ""
		;;
	'2_arg_optional_1_arg')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1
		expect_equals "$a" 1
		expect_equals "$b" ""
		;;
	'2_arg_optional_2_arg')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'2_arg_optional_3_arg_fail')
		add_arg a '?'
		add_arg b '?'
		getoptz_parse 1 2 3
		;;
	'1_arg_1_arg_optional_0_arg_fail')
		add_arg a
		add_arg b '?'
		getoptz_parse
		;;
	'1_arg_1_arg_optional_1_arg')
		add_arg a
		add_arg b '?'
		getoptz_parse 1
		expect_equals "$a" 1
		expect_equals "$b" ""
		;;
	'1_arg_1_arg_optional_2_arg')
		add_arg a
		add_arg b '?'
		getoptz_parse 1 2
		expect_equals "$a" 1
		expect_equals "$b" 2
		;;
	'1_arg_1_arg_optional_3_arg_fail')
		add_arg a
		add_arg b '?'
		getoptz_parse 1 2 3
		;;
	'1_arg_optional_1_arg_fail')
		add_arg a '?'
		add_arg b
		;;
	'1_arg*_0_arg')
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
