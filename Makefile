deploy:
	sudo -E ./deploy.csh

CutCopyPasteDB.sqlite3: schema.sql testdata.sql
	./buildDB.csh

clean:
	rm -f CutCopyPasteDB.sqlite

.PHONY: deploy clean
