module consts;

enum ErrorNotEnoughArgs = "Not enough arguments specified and no content file found, see ppcc --help for help.";
enum ErrorFileNotFound = "File not found!";
enum ErrorInvalidOption = "Invalid option!";

enum License = import("LICENSE");

enum HelpText = "Polyplex Content Compiler
Copyright (C) 2018, Polyplex
This is FREE SOFTWARE under the GPLv3 license!
To see the license run `ppcc license`.

Special Commands:
    license     |   Show license text
    init        |   Create a new project
    new         |   Create a new item
    help        |   Show helptext

Default Command:
    ppcc (content file) (options)

New Command:
    ppcc new <item> <name>

    Accepted Items:
        shader  |   A shader pair
        font    |   A font


Options:
    -h/--help   |   Show helptext
    -c/--cmp    |   Compile single file
    -p/--prj    |   Compile project file (default)
    -v          |   Verbose logging
    -of         |   Output debug info about project";
