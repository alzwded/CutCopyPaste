deploy:
	sudo ./deploy.csh

CutCopyPasteDB.sqlite: schema.sql
	# TODO
	exit 3

clean:
	rm -f CutCopyPasteDB.sqlite

.PHONY: deploy clean
