module compilers.texture;
import compilers;
import std.stdio, std.conv, std.uni;

/**
    Build a texture

    This function is mainly just for the edgecase of converting between textures
*/
bool buildTexture(PathData path, PCDRecipeItem recipeItem) {
    // If the input extension is the same as the specified subtype just skip converting
    if (path.inputExtension.verifyExtension(recipeItem.subType)) return false;

    // Same if there's no subtype specified
    if (recipeItem.subType is null || recipeItem.subType == "") return false;

    // Otherwise, we convert.
    
    // Get image type and image data
    ImageType typ = recipeItem.subType.toImgType;
    Image img = Image(loadFile(path.inputFile));

    // Convert the data
    ubyte[] data = img.convertTo(typ);

    // Write to file
    compileToPPC(data, Types.Image, path.outputFile, PPCCreateInfo(recipeItem.author, recipeItem.license));
    if (VERBOSE_MODE) {
        writeln("<", img.info.imageType.to!string ," -> " ~ typ.to!string ~ "> Converted successfully...");
        writeln("<", Types.Image.to!string, ">", " Compiled ", path.inputFile, "...");
    }
    return true;
}

/**
    Gets image type from file extension
*/
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