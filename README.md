# getoptz.sh

Command-line argument parser for Bash

Latest release: v0.3

Compatible with GNU Bash version >= 4.

## Quickstart
```bash
. getoptz.sh
add_arg name        --help "Your name."
add_opt verbose v   --help "Enable verbose mode."
getoptz_configure   --help "Print a hello world message."
getoptz_parse "$@"

# Your script begins here
[[ ! $verbose ]] || echo "[INFO] name=$name"
echo "Hello, $name!"
```

Execution:
<pre>
$ ./example_hello.sh world
Hello, world!

$ ./example_hello.sh -v world
[INFO] name=world
Hello, world!

$ ./example_hello.sh --help
Usage: hello.sh [<i>options</i>] [--] <i>name</i>
Description:
    Print a hello world message.

Arguments:
     <i>name</i>
            Your name.

Options:
     -h, --help
            Display this help and exit.

     -v, --verbose
            Enable verbose mode.
</pre>

## Features
* Automatic generation of a help message (-h or --help option).
* Options and arguments are mapped to Bash variables.
* Supports short options (-o1) and long options (--option=1).
* Options may be valued (-o1) or not (-o)
* Supports setting multiple flags at once (e.g. '-xvf' is the same as '-x -v -f')
* According to tradition, '--' signals the end of options.

## Examples
### Multiple arguments
Simply declare the arguments in the order they are expected:
```bash
. getoptz.sh
add_arg name
add_arg city
getoptz_parse "$@"
echo "Greetings from $city, $name!"
```

Execution:
```
$ ./example_multiple_args.sh John Paris
Greetings from Paris, John!
```

### Optional arguments
'?' will mark an argument as optional:
```bash
. getoptz.sh
add_arg name
add_arg city '?'
getoptz_parse "$@"

echo -n "Greetings"
[[ ! $city ]] || echo -n " from $city"
echo ", $name!"
```

Execution:
```
$ ./example_optional_args.sh John
Greetings, John!

$ ./example_optional_args.sh John Paris
Greetings from Paris, John!
```

### Array arguments
'+' allows an argument to be repeated 1 or more times.
'*' allows an argument to be repeated 0 or more times.
```bash
. getoptz.sh
add_arg names +
getoptz_parse "$@"

for n in "${names[@]}"; do
    echo "Hello, $n!"
done
```

Execution:
```
$ ./example_array_args.sh John Peter
Hello, John!
Hello, Peter!
```

### Default values
```bash
. getoptz.sh
add_opt type: t --default f --help 'f for files, d for directories'
getoptz_parse "$@"

[[ $type == @(f|d) ]] || getoptz_usage
find . -type $type
```

Execution
```
$ ./example_default_values.sh -tf
--> lists all regular files

$ ./example_default_values.sh -td
--> lists all directories

$ ./example_default_values.sh
--> lists all regular files
```

## API documentation

### getopz_parse
Syntax: ```getoptz_parse [args]...```

Parse the specified arguments.

### getopz_usage
Syntax: ``` getoptz_usage ```

Print a help message detailing the allowed options and arguments.

### add_opt
Syntax: ```add_opt OPTION_NAME[:] [ALIAS]... [--help HELP_STRING] [--group HELP_GROUP] [--dest DEST_VAR] [--default DEFAULT_VALUE]```

Add an option to the command line specification: valued option, or non-valued (*i.e.* flag).

Argument     | Description
------------ | -------------
*OPTION_NAME*  |  The primary option name. It may be a short option (single character) or a long option. If ```OPTION_NAME``` ends with ':', the option must have a value; otherwise it is a flag.<p><ul><li>At runtime, a variable named ```OPTION_NAME``` will be created with the value specified in the command line.<li>If the option is a flag, the corresponding variable will be set to '1'.<li>If the option is not set in the command line, a variable named *```OPTION_NAME```* is set to ```''``` (empty string).</ul>
*ALIAS*  |  0, 1 or more alias names that can be used to refer to this option. The alias may be a short option (single character) or a long option. At runtime, if the option is set in the command line using one of the alias names, the variable ```OPTION_NAME``` will be set with the corresponding value (note that no variable named ```ALIAS``` will be created).
*--group HELP_GROUP*  |  This allows grouping options together in the usage text. If ommitted, the option will go in the General "Options" sections.
*--dest DEST_VAR*  |  DEST_VAR allows to override the default mapping (```OPTION_NAME``` => variable name) for the variable name.
*--default DEFAULT_VALUE*  |  DEFAULT_VALUE allows to override the default value ('') for missing options.

### add_arg
Syntax: ```add_arg ARG_NAME [1 | '?' | '+' | '*' ] [--help HELP_STRING] [--default DEFAULT_VALUE]```

Accept an argument with the following multiplicity:
* ```1```: exactly 1 argument
* ```?```: 0 or 1 argument
* ```+```: 1 or more arguments
* ```*```: 0 or more arguments
   
Note: '?' and '*' are special caracters of the shell so they need to be quoted.

For multiplicities '+' and '*', the corresponding variable is a Bash array. Otherwise, the variable is a regular string.

### getoptz_print_report
Syntax: ``` getoptz_print_report ```

Reports all parsed arguments and options (for debugging).

## Compatibility
getoptz.sh has been tested in the following environments:
* Windows (Cygwin) with bash 4.3.33
* Linux with bash 4.1.2

Run ```./test_suite.sh``` with no arguments to test getoptz.sh in your environment.

