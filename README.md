# getoptz.sh

Command-line argument parser for Bash

v0.2 beta.

Works for GNU Bash version >= 4.

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

$ ./example_hello.sh World
Hello, World!

$ ./example_hello.sh -v world
[INFO] name=world
Hello, world!
</pre>

## Features
* Automatic generation of a help message (-h or --help option).
* Supports short options (-o1) and long options (--option=1).
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
Syntax: ```add_opt LONG_NAME[:] [SHORT_NAME] [--help HELP_STRING] [--dest DEST_VAR] [--default DEFAULT_VALUE]```

Add an option to the command line specification: valued option, or non-valued (*i.e.* flag).

If LONG_NAME ends with ':', the option must have a value; otherwise it is a flag.
* If a valued option is set at runtime, a variable named LONG_NAME is created with the specified value.
* If a flag is set at runtime, a variable named LONG_NAME is set to '1'.
* If the option is not set at runtime, a variable named LONG_NAME is set to '' (empty string).
   
Notes:
* SHORT_NAME must be a single character.
* LONG_NAME is mandatory whereas SHORT_NAME is not.
* DEST_VAR allows to override the default mapping (LONG_NAME => variable name) for the variable name.
* DEFAULT_VALUE allows to override the default value ('') for missing options.

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

## Restrictions, bugs
* Options require a long name. Having only a short name is forbidden, since the long name defines the name of the variable to be written.
* Setting multiple flags at once (e.g ```tar -xvf```) is not yet supported.
* Not production-ready yet!
