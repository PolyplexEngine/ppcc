module setup.project;
import project;
import std.datetime, std.conv, std.format, std.stdio;

// Seperate path and file imports to avoid collissions
import stdf = std.file, stdp = std.path;


/**
    Initialize project
*/
void doInit() {
    BaseDUBCfg config;
    SysTime now = Clock.currTime(UTC());

    config.targetName = repeatGet("Name");

    config.name = config.targetName.validifyName;

    config.description = repeatGet("Description");
    
    config.authors = repeatGetList("Author");

    config.copyright = "Copyright © " ~ now.year.text ~ ", " ~ config.authors[0];
    
    config.license = repeatGet("License");
    config.dependencies["pp"] = LatestPolyVer;

    stdf.write("dub.json", config.toSDL);
    stdf.write("content.sdl", config.getDefaultContent);
    stdf.mkdir("content");
    stdf.mkdir("raw");
    stdf.mkdir("source");
    stdf.write("source/app.d", import("templates/project/app.d"));
    stdf.write("source/game.d", import("templates/project/game.d").format(config.targetName));
}

/**
    Get list of elements repeatedly untill done
*/
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

/**
    Get value repeatedly untill a valid value has been recieved
*/
string repeatGet(string title) {
    string rd;
    do {
        write(title, ": ");
        rd = readln();
    } while (rd == "\n");

    // readln appends \n to string, remember to cut off that newline.
    return rd[0..$-1];
}

/**
    Make naming scheme valid
*/
string validifyName(string oldName) {
    import std.uni : toLower;
    import std.array : replace;
    return oldName.toLower.replace(" ", "-");
}