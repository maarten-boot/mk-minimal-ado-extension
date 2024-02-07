# Makefile

export DIR 			=	mytask
export AUTHOR		=	JustAnotherPublisher
export LICENSE		=	MIT
export VERSION		=	0.1.0
export NAME			=	test-ado-extension-test
export FRIENDLYNAME	=	Testing a azure devops extension pipeline
export DESCRIPTION	=	This is a test for a azure devops extension.

init: $(DIR)

$(DIR):
	./prep.sh 2>&1 | tee out

real-clean:
	rm -f out *.vsix overview.md  vss-extension.json
	rm -rf $(DIR) images
