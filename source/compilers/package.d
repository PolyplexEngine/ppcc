module compilers;
import
    compilers.font,
    compilers.shader,
    compilers.texture;
import std.file, std.path, std.string, std.stdio, std.conv;
import vibe.data.sdl, sdlang.parser : parseFile;

// import all the backend and type stuff.
public import ppc.backend, ppc.types, pcd, state;

/**
    Path data describing where files are, etc.
*/
struct PathData {
    /// Input path
    string inputPath;

    /// Input file
    string inputFile;

    /// Input file extension
    string inputExtension;

    /// Output path
    string outputPath;

    /// Output file
    string outputFile;
}

/**
    Gets a project (loads PCD file)
*/
PCD getProject(string file) {
    return loadPCD(file);
}

/**
    Runs through the recipes of a project file

    Each recipe will be built.
*/
void buildProject(string file) {
    PCD project = getProject(file);
    if (VERBOSE_MODE) writeln("Compiling ", file, "...");

    foreach(recipe; project.recipes) {
        buildRecipe(recipe, project);
    }
}

/**
    Ensure the existence of a path
*/
void ensurePath(string path) {
    if(!path.exists) {
        import std.file : mkdirRecurse;
        mkdirRecurse(path);
    }
}

/**
    Build a recipe.

    Iterates through the contents of a recipe and builds them.
*/
void buildRecipe(PCDRecipe recipe, PCD project) {
    foreach(resi; recipe.recipeItems) {
        if (VERBOSE_MODE) writeln("==== ", recipe.name, " ====");

        // Fetch path data
        PathData path;
        path.inputPath = buildPath(project.inputDirectory, recipe.path, resi.path.dirName);
        path.inputFile = buildPath(project.inputDirectory, recipe.path, resi.path);
        path.inputExtension = resi.path.baseName.extension;

        path.outputPath = buildPath(project.outputDirectory, recipe.path, resi.path.dirName);
        path.outputFile = buildPath(project.outputDirectory, recipe.path, resi.path.stripExtension~".ppc");


        // Ensure that the output path exists.
        ensurePath(path.outputPath);

        try {
            // Shader case
            switch (resi.type) {

                case RecipeType.Shader:
                    buildShader(path, resi);
                    break;

                case RecipeType.Texture:
                    if (!buildTexture(path, resi)) handleDefault(path.inputFile, path.outputFile, resi);
                    break;

                case RecipeType.Font:
                    buildFont(path, resi);
                    break;
                case RecipeType.Model:
                case RecipeType.Audio:
                case RecipeType.Data:
                    handleDefault(path.inputFile, path.outputFile, resi);
                    break;
                default:
                    throw new Exception("Unknown recipe type!");
            }
        } catch (Exception ex) {
            writeln("Compilation error ", ex.message, "\nSkipping ", path.inputFile, "...");
        }
    }
}

/**
    Handle default operation

    This just passes the type over to PPC and hopes it outputs the right file
*/
void handleDefault(string iFile, string oFile, PCDRecipeItem resi) {
    Types t = iFile.getTypeOf;
    compileToPPC(cast(ubyte[])read(iFile), t, oFile, PPCCreateInfo(resi.author, resi.license));
    if (VERBOSE_MODE) writeln("<", t.to!string, ">", " Compiled ", iFile, "...");
}

string[] getFilesByNameOrPathName(string directoryOrName) {
    string baseFileName = directoryOrName.baseName();
    if (directoryOrName.exists && isDir(directoryOrName)) {
        return getExtendedFiles(directoryOrName, baseFileName);
    }
    return getExtendedFiles(directoryOrName[0..$-(baseFileName.length)], baseFileName);
}

/**
    Gets all the files starting with the specified name in the specified directory
*/
string[] getExtendedFiles(string directory, string fname) {
    string[] toCompile;
    foreach(DirEntry file; dirEntries(directory, SpanMode.shallow, false)) {
        if (file.name.baseName.startsWith(fname)) {
            toCompile ~= file.name;
        }
    }
    return toCompile;
}

/**
    Builds a single file outside of project
*/
void buildFile(string file) {
    PPCCreateInfo createInfo;
    if (file.getTypeOf == Types.Shader) {
        writeln("Cannot compile single-shader, skipping...");
        return;
    }
    createInfo.author = "Clipsey";
    createInfo.license = "CC";
    Types t = compileToPPC(file, file.stripExtension~".ppc", createInfo);
    if (VERBOSE_MODE) writeln("<", t.to!string, ">", " Compiled ", file, "...");
}

/**
    Verifies that an extension is valid and is of the expected type
*/
bool verifyExtension(string input, string expected) {
    return (input !is null && input != "" && input[1..$] == expected);
}