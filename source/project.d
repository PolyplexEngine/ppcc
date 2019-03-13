module project;
import asdf;

/// What version of libpp to get.
enum PPVersionString = "~>0.0.5";

/// Basic DUB configuration
struct BaseDUBCfg {
public:
    /// Name of game
    string name;

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
    string toJson() {
        return this.serializeToJsonPretty;
    }

    /// Get SDLang string for content file.
    string getDefaultContent() {
        return getDefaultContentCfg(authors[0], license);
    }
}

string getDefaultContentCfg(string author, string license) {
    import std.format : format;
    return `// The default author to be listed for files
info:author "%s"

// The default license to be listed for files
info:license "%s"

// Output folder (what your game should read)
path:output "content/"

// Input folder (where your raw content (.png, .mp3, etc.) should be)
path:input "raw/"

// Basic recipe
recipe name="Main" {
    // Insert recipe items here.    
}`.format(author, license);
}