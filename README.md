# XCodeControl

A little program to control `pbxproj` files from XCode projects through the command line.

## Project Status

Currently the program is in beta stage. It is useable for a very reduced set of operations, actually one operation: You can add files to the default source code path of a xcode project and a build rule, based on the file extension will be added to all targets the project contains.

If no file is openend by an `-o` option, the first `*.xcodeproj/project.pbxproj` file is chosen, if that's the only one in the current working directory, just as xcodebuild works, too.

The single operation that currently works is `-b` or `--buildSourceFile` to add a source file in the default source file path of the project, here `XCodeControl`, and a build rule to all targets.

The default output file is always `./pbxproj.out`. You can specify `-s ""` (with an empty filename) to save the project where you loaded from. _You should save your pbxproj files with git or backup them before you let a beta beast play with them._

This behaviour is tested and seems to work.
It should be easy to customize the program. I will describe how, in a short amount of time.

# Example

When you checked out the XCodeControl Project to your favourite MacOS with XCode you can compile the program simply with

	xcodebuild -configuration Debug |grep -i 'error:\|warning'

, while the grep just drops all the verbose output and just shows errors or warnings.

If you add `test.m` to the project by

	Build/Debug/XCodeControl -o XCodeControl.xcodeproj/project.pbxproj -b test.m

and

	cp pbxproj.out XCodeControl.xcodeproj/project.pbxproj

the file `XCodeControl/test.m` becomes part of the project. You can check this behaviour, for uncommenting the line `XCodeControl/dict.m:13`

	// #define TEST_FUNCTION 1

. The first output line should then be `success!`.

To revert the modified pbxproj file just

	git checkout HEAD -- XCodeControl.xcodeproj/project.pbxproj

. The project.pbxproj in the repository actually isn't the original, but a replaced version from a read-write cycle of the XCodeControl target itself. You can see the original file in the git history

	git show --name-only b30ee477118da2d322f7fd5b496956a49bc04a17:XCodeControl.xcodeproj/project.pbxproj

# More Documents

While the project evolves I will write some more documents about the structure of the code and how to use, modify and extend it. These documents live in the [`docs/`](docs/) folder.
