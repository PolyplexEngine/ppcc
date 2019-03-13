module pcd;
import std.file;
import sdlang;
import sdlang.ast;

enum RecipeType : string {
    Texture = "texture",
    Audio = "audio",
    Sound = "sound",
    Shader = "shader",
    Font = "font",
    Model = "model",
    Data = "data"
}

// TODO: Remove text length limits?

public struct PCD {
public:
    char[32] author             = [];
    char[16] license            = [];
    string outputDirectory      = "";
    string inputDirectory       = "";
    PCDRecipe[] recipes         = [];
}

public struct PCDRecipe {
public:
    string name                 = "Unnamed Recipe";
    string path                 = "";
    string platform             = "";
    PCDRecipeItem[] recipeItems = [];
}
public struct PCDRecipeItem {
public:
    RecipeType type;
    string subType              = "";
    string path                 = "";
    char[32] author             = [];
    char[16] license            = [];
}

PCD loadPCD(string file) {
    PCD output;
    Tag[] recipeTags;

    string pcd = readText(file);
    Tag root = parseSource(pcd, file);
    string iAuthor = root.getTag("info:author").getValue!string;
    string iLicense = root.getTag("info:license").getValue!string;
    immutable string iOutputDirectory = root.expectTagValue!string("path:output");
    immutable string iInputDirectory = root.getTagValue!string("path:input");
    
    foreach(Tag t; root.all.tags) {
        if (t.namespace == "recipe" || t.name == "recipe") {
            recipeTags ~= t;
        }
    }

    output.recipes = loadRecipes(recipeTags, iAuthor, iLicense);
    output.license = (iLicense.length >= 16) ? iLicense[0..16] : iLicense.doPadding(16);
    output.author = (iAuthor.length >= 32) ? iAuthor[0..32] : iAuthor.doPadding(32);
    output.outputDirectory = iOutputDirectory;
    output.inputDirectory = iInputDirectory;
    return output;
    
}

PCDRecipe[] loadRecipes(Tag[] tags, string rootauth, string rootlice) {
    PCDRecipe[] recipes;

    foreach(Tag recipe; tags) {
        PCDRecipe recip;
        recip.name = recipe.getAttribute!string("name");
        recip.platform = recipe.namespace;
        recip.path = recipe.getAttribute!string("path");
        foreach(Tag recipeItem; recipe.all.tags) {
            PCDRecipeItem item;
            // Basic item info
            item.type = cast(RecipeType)recipeItem.name;
            item.subType = recipeItem.getAttribute!string("type");
            item.path = recipeItem.expectValue!string;

            // Author and license info
            string iAuthor = recipeItem.getAttribute!string("author");
            string iLicense = recipeItem.getAttribute!string("license");
            if(iAuthor == "") iAuthor = rootauth;
            if(iLicense == "") iLicense = rootlice;
            item.author = (iAuthor.length >= 32) ? iAuthor[0..32] : iAuthor.doPadding(32);
            item.license = (iLicense.length >= 16) ? iLicense[0..16] : iLicense.doPadding(16);


            recip.recipeItems ~= item;
        }

        recipes ~= recip;
    }
    return recipes;
}

/// Ugly method to do some padding.
char[] doPadding(char[] data, int length) {
    data.length = length;
    return data;
}
char[] doPadding(string data, int length) {
    return doPadding(cast(char[])data, length);
}