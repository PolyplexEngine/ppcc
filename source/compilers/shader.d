module compilers.shader;
import compilers;
import ppc.types;
import ppc.backend.loaders.shader.psgl;
import std.stdio, std.file, std.uni;

/**
    Builds a shader
*/
void buildShader(PathData path, PCDRecipeItem recipeItem) {
    switch(recipeItem.subType.toLower) {

        case "psgl", "":
            /// Create shader object
            Shader s;
            foreach(sFile; path.inputPath.getExtendedFiles(recipeItem.path)) {
                ShaderType t = sFile.toShaderType;
                s.shaders[t] = GLSLShader(cast(ubyte[])readText(sFile));
            }

            // Compile shader object
            ubyte[] psgl = savePSGL(s);

            // Package shader
            PPCCreateInfo createInfo = PPCCreateInfo(recipeItem.author, recipeItem.license);
            compileToPPC(psgl, Types.Shader, path.outputFile, createInfo);
            if (VERBOSE_MODE) writeln("<Shader> Compiled shaders to PSGL in ", path.outputFile, "...");
            break;
        default:
            throw new Exception("No other types are supported.");

    }
}