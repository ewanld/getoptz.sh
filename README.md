# getoptz.sh

Command-line argument parser for Bash

v0.1 alpha.

Works for GNU Bash version >= 4.

## Features
* Automatic generation of a help message (-h or --help option).
* Handles optional arguments, array arguments.

## Basic usage
```bash
. getoptz.sh

# Variable 'name' will be set to the value of the first argument
add_arg name        --help "Your name."

# A flag (-v or --verbose)
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

## Advanced usage
TODO

## Restrictions, bugs
* Options require a long name. Having only a short name is forbidden, since the long name defines the name of the variable to be written.
