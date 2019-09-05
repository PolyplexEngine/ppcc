module compilers.font;
import compilers;
import std.stdio;
import app;

/**
    Builds a font file in to a font bitmap with accompanying information
*/
void buildFont(PathData path, PCDRecipeItem recipeItem) {
    if (path.inputExtension.verifyExtension("sdl")) {
        
        // Get the typeface
        TypeFace tf = getTypeFace(path.inputFile);

        // Compile the typeface in to a PPC file
        compileToPPC(
            
            // Convert font to font bitmap
            tf.convert(), 

            // It's an image
            Types.Image, 

            // To output file path
            path.outputFile,

            // Embed our creator info
            PPCCreateInfo(
                recipeItem.author, 
                recipeItem.license));

        // Some debug stuff
        if (VERBOSE_MODE) {
            writeln("<FontDescription -> BMF> Converted successfully...");
            writeln("<Font>", " Compiled ", path.outputFile, "...");
        }
    }
}

TypeFace getTypeFace(string file) {
    import vibe.data.sdl : deserializeSDLang;
    import sdlang.parser : parseFile;
    return TypeFace(deserializeSDLang!FontDescription(parseFile(file)));
}