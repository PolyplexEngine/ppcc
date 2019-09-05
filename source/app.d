module app;
import std.conv, std.stdio, std.string, std.format;
import consts, compilers, pcd, setup, state;
import std.file : exists;
import std.algorithm : canFind;

void main(string[] args) {
    // Turn on verbose mode if any parameters have -v
    VERBOSE_MODE = args.canFind("-v");

    if (args.length == 1) {
        if (!exists("content.sdl")) {
            writeln(ErrorNotEnoughArgs);
            return;
        }
        writeln("Compiling project...");
        buildProject("content.sdl");
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

    if (args[1] == "new") {
        writeln("TODO");
        return;
    }

    if (args.length == 2 && args[1] == "-v") {
        if (!exists("content.sdl")) {
            writeln(ErrorNotEnoughArgs);
            return;
        }

        buildProject("content.sdl");
    }

    if (args.canFind("--help", "-h", "help")) {
        writeln(HelpText);
        return;
    }


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
        buildFile(file);
    }
    foreach(project; prjCompileActions) {
        buildProject(project);
    }
    if (VERBOSE_MODE) writeln("Compilation completed.");
}