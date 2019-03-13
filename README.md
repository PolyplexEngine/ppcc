# Polyplex Content Compiler

PPCC is a tool for converting various file formats in to a generic container format that can be used in polyplex.

The container format allows for license and author information to be baked in to the content.
As well PPCC can compile GLSL shaders in to a small tightly packed shader container to keep file density low.

# How to use

The basic workflow of PPCC is to make a content.sdl file containing the neccesary information to build your content.
You can check the content.sdl file in this repository or check the wiki for further instructions on how to write content.sdl files.

If there's an content.sdl file in the directory you are in you simply run `ppcc` and the files should be compiled according to the content description.

Otherwise you can choose files directly using `ppcc -c (files)`.

```
Special Commands:
    license     |   Show license text
    init        |   Create a new project
    help        |   Show helptext

General Command layout:
ppcc (content file) (options)

Options:
    -h/--help   |   Show helptext
    -c/--cmp    |   Compile single file
    -p/--prj    |   Compile project file (default)
    -v          |   Verbose logging
    -of         |   Output debug info about project```