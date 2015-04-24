# getoptz.sh
Command-line argument parser for Bash

Works for GNU Bash version >= 4.

## Features
* Automatic generation of a help message (-h or --help option).
* Handles optional arguments, array arguments.

## Basic usage
```bash
. getoptz.sh

# Variable 'file' will be set to the value of the first argument
add_arg name        --help "Your name."

# A flag (-v or --verbose)
add_opt verbose v   --help "Enable verbose mode."

getoptz_configure   --help "Help message for your script."
getoptz_parse "$@"

# Your script begins here
[[ ! $verbose ]] || echo "name=$name"
echo "Hello, $name!"
```

You get the following help message:
<pre>
$ ./hello.sh --help
Usage: hello.sh [<i>options</i>] [--] <i>name</i>
Description:
    Help message for your script.

Arguments:
     <i>name</i>
            Your name.

Options:
     -h, --help
            Display this help and exit.

     -v, --verbose
            Enable verbose mode.
</pre>

## Advanced usage
TODO
