#!/bin/bash
#' Copyright (C) 2022 by Ben Taft

#' Build a python package
#'
#' Parameters
#' ----------
#' 1. package_name : this should be a valid name for PIP and as a python module
#' 2. author_name : this should be quoted, I think.
#' 3. version : something like 0.0.1, which is the default

function usage_message {
	echo "usage: $1 package_name ..."
	echo "  -a|--author author_name_in_quotes"
	echo "    The name of the author, which must be quoted if it has more than"
    echo "    one word in it. The default is 'Anonymous'."
	echo "  -e|--email email_address"
	echo "    The email address of the author, doesn't(?) need to be quoted."
	echo "  -r|--repo|--repository url_of_repository"
	echo "    The URL of an existing git repo that the package will belong to."
	echo "    If it's omitted, the command will create a new local repo."
	echo "  -v|--version version_string"
	echo "    Some version code for the package, defaulting to '0.0.1'."
	exit
}

AUTHOR_NAME=Anonymous
EMAIL_ADDRESS=an@nymo.us
VERSION=0.0.1
REPOSITORY=
PACKAGE_NAME=$1
shift

while (( "$#" )); do
	case "$1" in
		-a|--author)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				AUTHOR_NAME=$2
				shift
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			shift
			;;
		-e|--email)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				EMAIL_ADDRESS=$2
				shift
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			shift
			;;
		-r|--repo|--repository)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				REPOSITORY=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-v|--version)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				VERSION=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		*)
			usage_message $(basename $0)
			;;
	esac
done

if ! [[ -n $PACKAGE_NAME ]]; then
	usage_message $(basename $0)
fi

CMD_DIR=$(dirname $(dirname $(realpath ${BASH_SOURCE})))

mkdir -p ${PACKAGE_NAME}
cd ${PACKAGE_NAME}

# version control

git init

# set up a virtual environment

python3 -m venv --symlinks env
source env/bin/activate
python3 -m pip install --upgrade \
		pip \
		build \
		numpydoc \
		pytest \
		sphinx \
		setuptools \
		wheel

# create the package structure

mkdir src
mkdir src/${PACKAGE_NAME}
touch src/${PACKAGE_NAME}/__init__.py
echo "print('hello, world!')" > src/${PACKAGE_NAME}/__main__.py
echo "" >> src/${PACKAGE_NAME}/__main__.py

mkdir tests
touch tests/conftest.py
touch tests/__init__.py

TEMPLATE_DIR=${CMD_DIR}/templates

TEMPLATE_FILES=$(find ${TEMPLATE_DIR} -type f)

for f in $TEMPLATE_FILES; do
	cp $f ${f#$TEMPLATE_DIR/}
	perl -pi -e "s|replaceWithPackageName|${PACKAGE_NAME}|g" ${f#$TEMPLATE_DIR/}
	perl -pi -e "s|replaceWithAuthorName|${AUTHOR_NAME}|g" ${f#$TEMPLATE_DIR/}
	perl -pi -e "s|replaceWithEmail|${EMAIL_ADDRESS}|g" ${f#$TEMPLATE_DIR/}
	perl -pi -e "s|replaceWithVersionNumber|${VERSION}|g" ${f#$TEMPLATE_DIR/}
	perl -pi -e "s|replaceWithRepository|${REPOSITORY}|g" ${f#$TEMPLATE_DIR/}
done

sphinx-quickstart sphinx \
				  --sep \
				  -l en \
				  -p ${PACKAGE_NAME} \
				  -a "${AUTHOR_NAME}" \
				  -r "${VERSION}" \
				  --ext-autodoc \
				  --ext-doctest \
				  --ext-intersphinx \
				  --extensions=numpydoc,sphinx.ext.autosummary

python3 -m build --no-isolation .

python3 -m pip install --editable .

python3 -m pip freeze > REQUIREMENTS.txt

python3 setup.py build_sphinx

deactivate

git add -A .
git commit -m "initialized package ${PACKAGE_NAME}"
git branch -M main

if [[ -n $REPOSITORY ]]; then
	git remote add origin $REPOSITORY
	git push -u origin main
fi
