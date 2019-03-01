import pcd;
import std.conv;
import std.stdio;
import std.string;
import ppc.types.image;

enum ErrorNotEnoughArgs = "Not enough arguments specified and no content file found, see ppcc --help for help.";
enum ErrorFileNotFound = "File not found!";
enum ErrorInvalidOption = "Invalid option!";

enum HelpText = "Polyplex Content Compiler
Copyright (C) 2018, Clipsey

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

        compileProject("content.sdl", false);
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

import ppc.backend;
import ppc.types : Types, getTypeOf;
import std.file;
import std.path;
import std.string;

void compileProject(string file, bool verbose = false) {
    PCD proj = getProject(file);
    if (verbose) writeln("Compiling ", file, "...");

    foreach(res; proj.recipes) {
        if (verbose) writeln("==== ", res.name, " ===");
        foreach(resi; res.recipeItems) {
            string pth = res.path;
            if (pth != "") {
                version(Posix) {
                    pth = res.path;
                } else {
                    pth = res.path;
                }
            }
            string iPath = buildPath(proj.inputDirectory, pth, resi.path.dirName);
            string iFile = buildPath(proj.inputDirectory, pth, resi.path);
            string oPath = buildPath(proj.outputDirectory, pth, resi.path.dirName);
            string oFile = buildPath(proj.outputDirectory, pth, resi.path.stripExtension~".ppc");
            string iExt = resi.path.baseName.extension;

            if(!oPath.exists) {
                import std.file : mkdirRecurse;
                mkdirRecurse(oPath);
            }
            try {
                // Shader case
                switch (resi.type) {
                    case RecipeType.Shader:
                        // Default is PSGL
                        if (resi.subType == "psgl" || resi.subType == "") {
                            import ppc.types;
                            import ppc.backend.loaders.shader.psgl;

                            /// Create shader object
                            Shader s;
                            foreach(sFile; iPath.getExtendedFiles(resi.path)) {
                                ShaderType t = sFile.toShaderType;
                                s.shaders[t] = GLSLShader(cast(ubyte[])readText(sFile));
                            }

                            // Compile shader object
                            ubyte[] psgl = savePSGL(s);

                            // Package shader
                            PPCCreateInfo createInfo = PPCCreateInfo(resi.author, resi.license);
                            compileToPPC(psgl, Types.Shader, oFile, createInfo);
                            if (verbose) writeln("<Shader> compiled shaders to PSGL in ", oFile, "...");
                        } else {
                            throw new Exception("No other types are supported.");
                        }
                        break;
                    case RecipeType.Texture:
                        if (resi.subType !is null && resi.subType != "") {
                            if (resi.subType != iExt[1..$]) {
                                ImageType typ = resi.subType.toImgType;
                                Image img = Image(loadFile(iFile));
                                ubyte[] data = img.convertTo(typ);
                                compileToPPC(data, Types.Image, oFile, PPCCreateInfo(resi.author, resi.license));
                                if (verbose) {
                                    writeln("<", img.info.imageType.to!string ," -> " ~ typ.to!string ~ "> Converted successfully...");
                                    writeln("<", Types.Image.to!string, ">", " Compiled ", iFile, "...");
                                }
                                break;
                            }
                        }
                    case RecipeType.Font:
                    case RecipeType.Model:
                    case RecipeType.Audio:
                    case RecipeType.Data:
                        handleDefault(verbose, iFile, oFile, resi);
                        break;
                    default:
                        throw new Exception("Unknown recipe type!");
                }
            } catch (Exception ex) {
                writeln("Compilation error ", ex.message, ", skipping", iFile, "...");
            }
        }
    }
}

void handleDefault(bool verbose, string iFile, string oFile, PCDRecipeItem resi) {
    Types t = iFile.getTypeOf;
    compileToPPC(cast(ubyte[])read(iFile), t, oFile, PPCCreateInfo(resi.author, resi.license));
    if (verbose) writeln("<", t.to!string, ">", " Compiled ", iFile, "...");
                    
}

string[] getExtendedFiles(string directory, string fname) {
    string[] toCompile;
    foreach(DirEntry file; dirEntries(directory, SpanMode.shallow, false)) {
        if (file.name.baseName.startsWith(fname)) {
            toCompile ~= file.name;
        }
    }
    return toCompile;
}

void compileFile(string file, bool verbose = false) {
    PPCCreateInfo createInfo;
    if (file.getTypeOf == Types.Shader) {
        writeln("Cannot compile single-shader, skipping...");
        return;
    }
    createInfo.author = "Clipsey";
    createInfo.license = "CC";
    Types t = compileToPPC(file, file.stripExtension~".ppc", createInfo);
    if (verbose) writeln("<", t.to!string, ">", " Compiled ", file, "...");
}

PCD getProject(string file) {
    import std.file;
    return loadPCD(file);
}

ImageType toImgType(string str) {
    switch (str.toLower) {
        case "png":
            return ImageType.PNG;
        case "tga":
        case "targa":
            return ImageType.TGA;
        case "pti":
            return ImageType.PTI;
        default:
            throw new Exception("Invalid image type name! (supported are: png, tga, targa and pti)");
    }
}