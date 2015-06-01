all: docs/optionArray.html

push: docs/optionArray.html docs/description.md upload
	git push -q github; git push -q kundenweb; git push -q origin master:update

upload: docs/optionArray.html docs/description.md README.md
	rsync -c README.md ingo@zulu1343:/home/eoa/wiki/sites/eoawiki/Anleitung/XCodeControl/
	rsync -c highlight.css docs/optionArray.html docs/*.md ingo@zulu1343:/home/eoa/wiki/sites/eoawiki/Anleitung/XCodeControl/docs/

docs/optionArray.html: XCodeControl/dict.m Makefile
	@N=`sed -n '/^static Option progopts/=' XCodeControl/dict.m`; sed -n $$N',/^};/p' XCodeControl/dict.m|highlight --syntax=objc -l -m $$N > docs/optionArray.html

docs/description.md: XCodeControl/dict.m Makefile
	@N=`sed -n '/^static Option progopts/=' XCodeControl/dict.m`; printf 'g/\(option array at .XCodeControl\/dict.m:\)[0-9]\+/s/\(option array at .XCodeControl\/dict.m:\)[0-9]\+/\\1'$$N'/\nw\nq\n' | ed docs/description.md
clean:
	@rm -f docs/optionArray.html
