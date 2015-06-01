all: docs/optionArray.html

upload: docs/optionArray.html
	rsync -c highlight.css docs/optionArray.html docs/description.md ingo@zulu1343:/home/eoa/wiki/sites/eoawiki/Anleitung/XCodeControl/docs

docs/optionArray.html: XCodeControl/dict.m Makefile
	@sed -n '95,107p' XCodeControl/dict.m|highlight --syntax=objc -l -m 95 > docs/optionArray.html

clean:
	@rm -f docs/optionArray.html
