import pcd;
import std.conv;
import std.stdio;
import std.string;
import std.format;
import compilation;

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

Command layout:
ppcc (content file) (options)

Arguments:
    -h/--help   |   Show helptext
    -c/--cmp    |   Compile single file
    -p/--prj    |   Compile project file (default)
    -v          |   Verbose logging
    -of         |   Output debug info about project";

void main(string[] args) {
    import std.file : exists;
    import std.algorithm : canFind;
    if (args.length == 1) {
        if (!exists("content.sdl")) {
            writeln(ErrorNotEnoughArgs);
            return;
        }
        writeln("Compiling project...");
        compileProject("content.sdl", false);
        return;
    }

    if (args[1] == "license") {
        writeln(License);
        return;
    }

    if (args[1] == "init") {
        doInit();
        return;
    }

    if (args.length == 2 && args[1] == "-v") {
        if (!exists("content.sdl")) {
            writeln(ErrorNotEnoughArgs);
            return;
        }

        compileProject("content.sdl", true);
    }

    if (args.canFind("--help")) {
        writeln(HelpText);
        return;
    }

    bool verbose = args.canFind("-v");

    string[] aArgs = args[1..$];
    string[] sCompileActions;
    string[] prjCompileActions;
    bool awaitingS;
    if (aArgs[0] == "-of") {
        if (aArgs.length == 2) {
            writeln(getProject(aArgs[1]).to!string);
        }
    }

    foreach(arg; aArgs) {
        if (arg == "-v") continue;
        if (arg == "-c" || arg == "--cmp") {
            awaitingS = true;
            continue;
        }
        if (arg == "-p" || arg == "--proj") {
            awaitingS = false;
            continue;
        }

        if (awaitingS) {
            if (!exists(arg)) {
                writeln(ErrorFileNotFound, " (", arg, ")");
                return;
            }

            sCompileActions ~= arg;
            continue;
        }
        
        if (arg[0] == '-') {
            writeln(ErrorInvalidOption, " (", arg, ")");
            return;
        }


        if (!exists(arg)) {
            writeln(ErrorFileNotFound, " (", arg, ")");
            return;
        }

        prjCompileActions ~= arg;
    }
    foreach(file; sCompileActions) {
        compileFile(file, verbose);
    }
    foreach(project; prjCompileActions) {
        compileProject(project, verbose);
    }
    if (verbose) writeln("Compilation completed.");
}

import project;
import std.datetime;
import stdf = std.file;
import stdp = std.path;

void doInit() {
    BaseDUBCfg config;
    SysTime now = Clock.currTime(UTC());

    config.targetName = repeatGet("Name");

    config.name = config.targetName.validifyName;

    config.description = repeatGet("Description");
    
    config.authors = repeatGetList("Author");

    config.copyright = "Copyright © " ~ now.year.text ~ ", " ~ config.authors[0];
    
    config.license = repeatGet("License");
    config.dependencies["pp"] = PPVersionString;

    stdf.write("dub.json", config.toJson);
    stdf.write("content.sdl", config.getDefaultContent);
    stdf.mkdir("content");
    stdf.mkdir("raw");
    stdf.mkdir("source");
    stdf.write("source/app.d", import("defaultTemplate/app.d"));
    stdf.write("source/game.d", import("defaultTemplate/game.d").format(config.targetName));
}

string[] repeatGetList(string title) {
    string[] outList;
    string rd = "\n";
    do {
        write("[Empty when done] ", title, "...: ");
        rd = readln();

        // readln appends \n to string, remember to cut off that newline.
        if (rd != "\n") outList ~= rd[0..$-1];
    } while (rd != "\n" || outList.length == 0);
    return outList;
}

string repeatGet(string title) {
    string rd;
    do {
        write(title, ": ");
        rd = readln();
    } while (rd == "\n");

    // readln appends \n to string, remember to cut off that newline.
    return rd[0..$-1];
}

string validifyName(string oldName) {
    import std.uni : toLower;
    import std.array : replace;
    return oldName.toLower.replace(" ", "-");
}