# Description

The `XCodeControl` program works as a linear operation parser. Most arguments take a mandatory argument,
but generally options can have one mandatory, one optional or no argument.

Currently the operations are read as command line options in the given order. When the input file operation is implemented
the same control words or characters can be read from input files.

The _option language_ is defined in the option array at `XCodeControl/dict.m:95`ff:
<iframe src="optionArray.html" style="width:100%; height:16.5em; border:none;">
</iframe>
