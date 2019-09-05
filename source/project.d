module project;
import sdlang, sdlang.ast;
import vibe.data.sdl;

/// The default version of libpp to get.
enum LatestPolyVer = "~>0.0.65";

/// Basic DUB configuration
struct BaseDUBCfg {
public:
    /// Name of game
    string name;

    /// The target file name
    string targetName;

    /// Description of game
    string description;

    /// Authors of game
    string[] authors;

    /// Game copyright string
    string copyright;

    /// License of game
    string license;

    /// Game dependencies
    string[string] dependencies;

    /// Get JSON string
    string toSDL() {
        return serializeSDLang(this).toSDLDocument;
    }

    /// Get SDLang string for content file.
    string getDefaultContent() {
        return getDefaultContentCfg(authors[0], license);
    }
}

string getDefaultContentCfg(string author, string license) {
    import std.format : format;
    return import("project.sdl").format(author, license);
}