all: docs/optionArray.html

push:
	git push -q github; git push -q kundenweb; git push -q origin master:update

upload: docs/optionArray.html
	rsync -c highlight.css docs/optionArray.html docs/description.md ingo@zulu1343:/home/eoa/wiki/sites/eoawiki/Anleitung/XCodeControl/docs

docs/optionArray.html: XCodeControl/dict.m Makefile
	@sed -n '/^static Option progopts/,/^};/p' XCodeControl/dict.m|highlight --syntax=objc -l -m 95 > docs/optionArray.html

clean:
	@rm -f docs/optionArray.html
