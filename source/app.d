import std.stdio;
import ppc;
import ppc.utils;

import std.random;
import std.algorithm.searching;

import std.conv;

import std.path;

void main(string[] args)
{
	if (args.length > 1) {
		if (args[1] == "--convert" || args[1] == "-c") {
			for (int i = 2; i < args.length; i++) {
				//Setup base factories.
				SetupBaseFactories();
				
				if (args[i].endsWith(".png") || args[i].endsWith(".jpeg") || args[i].endsWith(".jpg") || args[i].endsWith(".bmp")) {
					ConvertImage(args[i]);
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
	} else {
		writeln("Not enough arguments!
		
Usage:
ppcc --convert (input file) (output file name (WITHOUT .ppc extension)) (etc.)");
	}
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
	img.Convert(data);
	WriteContentFile(img, file);
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
	raw.Convert(data);
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