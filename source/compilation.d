module compilation;
import ppc.backend;
import ppc.types;
import std.file;
import std.path;
import std.string;
import pcd;
import std.stdio;
import std.conv;
import vibe.data.sdl;
import sdlang.parser : parseFile;

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
                        if (iExt !is null) {
                            if (iExt[1..$] == "sdl") {
                                TypeFace tf = TypeFace(deserializeSDLang!FontDescription(parseFile(iFile)));
                                compileToPPC(tf.convert(), Types.Image, oFile, PPCCreateInfo(resi.author, resi.license));
                                if (verbose) {
                                    writeln("<FontDescription -> BMF> Converted successfully...");
                                    writeln("<Font>", " Compiled ", iFile, "...");
                                }
                            }
                        }
                        break;
                    case RecipeType.Model:
                    case RecipeType.Audio:
                    case RecipeType.Sound:
                    case RecipeType.Data:
                        handleDefault(verbose, iFile, oFile, resi);
                        break;
                    default:
                        throw new Exception("Unknown recipe type!");
                }
            } catch (Exception ex) {
                writeln("Compilation error ", ex.message, "\nSkipping ", iFile, "...");
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