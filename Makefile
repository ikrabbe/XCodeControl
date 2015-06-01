all: docs/optionArray.html

push: docs/optionArray.html upload
	git push -q github; git push -q kundenweb; git push -q origin master:update

upload: docs/optionArray.html README.md
	rsync -c README.md ingo@zulu1343:/home/eoa/wiki/sites/eoawiki/Anleitung/XCodeControl/
	rsync -c highlight.css docs/optionArray.html docs/*.md ingo@zulu1343:/home/eoa/wiki/sites/eoawiki/Anleitung/XCodeControl/docs/

docs/optionArray.html: XCodeControl/dict.m Makefile
	@sed -n '/^static Option progopts/,/^};/p' XCodeControl/dict.m|highlight --syntax=objc -l -m 95 > docs/optionArray.html

clean:
	@rm -f docs/optionArray.html
