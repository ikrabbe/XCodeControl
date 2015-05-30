# XCodeControl

A little program to control `pbxproj` files from XCode projects through the command line.

## Project Status

Currently the program is in beta stage. It is useable for a very reduced set of operations, actually one operation: You can add files to the default source code path of a xcode project and a build rule, based on the file extension will be added to all targets the project contains.

The pbxproj file is read from a static path `XCodeControl.xcodeproj/project.pbxproj`, so from this project itself. We need an option to control that input file location.

The only option that currently works is `-b` or `--buildSourceFile` to add a source file in the default source file path of the project, here `XCodeControl`, and a build rule to all targets.

The output file is always pbjxproj.out.

This behaviour is tested and seems to work.
The program should be easily to customize.

I will describe how to customize, in a short amount of time.

# Example

If you add `test.m` to the project by

	Build/Debug/XCodeControl -b test.m

and

	# be carefull you should save you original file first:
	# cp XCodeControl.xcodeproj/project.pbxproj pbxproj.save
	cp pbxproj.out XCodeControl.xcodeproj/project.pbxproj

the file `XCodeControl/test.m` becomes part of the project. You can check this behaviour, for uncommenting the line

	// #define TEST_FUNCTION 1

in `XCodeControl/dict.m`. The first output line should then be `success!`.

#### ... more to come soon ... Stay tuned.
