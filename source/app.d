import std.stdio;
import ppc;
import ppc.utils;

import std.random;
import std.algorithm.searching;
import std.conv;
import std.path;
import std.file;

import sdlang;
import cfile;

void main(string[] args_o)
{
	string[] args = args_o[1..$];
	try {
		if (args.length < 2) {
			if (args.length == 0) {
				HandleProjectFile("content.sdl");
			} else {
				HandleProjectFile(args[0]);
			}
		} else {
			if (args[0] == "--convert" || args[0] == "-c") {
				for (int i = 1; i < args.length; i++) {
					//Setup base factories.
					SetupBaseFactories();
					
					if (args[i].endsWith(".png") || args[i].endsWith(".jpeg") || args[i].endsWith(".jpg") || args[i].endsWith(".bmp")) {
						ConvertImage(args[i]);
					} else if (args[i].endsWith(".ogg")) {
						ConvertAudio(args[i]);
					} else {
						writeln("<Warning> unknown filetype...");
						ConvertRaw(args[i]);
					}
				}
				writeln("Done.");
				return;
			} else {
				writeln("Invalid parameters!
				
	Usage:
	ppcc --convert (input file) (output file name (WITHOUT .ppc extension)) (etc.)");
			}
		}
	} catch (Exception ex) {
		writeln("Failed building PPCC project!\nReason:\n"~ex.message);
	}
}

void HandleProjectFile(string file) {
	if (!exists(file)) throw new Exception("Project file " ~ file ~ " was not found!");
	ContentFileDefinition def = new ContentFileDefinition(parseSource(file));

}

void ConvertImage(string file) {
	string name = stripExtension(file);

	Image img = new Image(name);
	File f = File(file);
	ubyte[] data = [];
	foreach(ubyte[] buff; f.byChunk(4096)) {
		data = Combine(data, buff);
	}
	f.close();
	img.Convert(data, 0);
	WriteContentFile(img, file);
}

void ConvertAudio(string file) {
	string name = stripExtension(file);
	Audio aud = new Audio(name);
	File f = File(file);
	ubyte[] data = [];
	foreach(ubyte[] buff; f.byChunk(4096)) {
		data = Combine(data, buff);
	}
	f.close();
	aud.Convert(data, AudioStorageType.OGG);
	writeln("A");
	WriteContentFile(aud, file);
}

void ConvertRaw(string file) {
	string name = stripExtension(file);

	RawContent raw = new RawContent(name);
	File f = File(file);
	ubyte[] data;
	foreach(ubyte[] buff; f.byChunk(4096)) {
		data = Combine(data, buff);
	}
	f.close();
	raw.Convert(data, 0);
	WriteContentFile(raw, file);
}

void WriteContentFile(Content input, string name) {
	ContentFile f = new ContentFile(FileTypeId.Content);
	string oname = stripExtension(name);
	f.Data = input;
	f.Info = new ContentInfo();
	f.Info.Author = "TODO";
	f.Info.License = ContentLicense.Propriatary;
	f.Info.Message = "TODO";
	f.Save(oname~".ppc");
	writeln("<Convert::" ~ input.TypeID.text ~ "> " ~ name ~ " -> " ~ oname~".ppc");
}