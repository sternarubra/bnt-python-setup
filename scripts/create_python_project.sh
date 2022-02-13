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
MAKE_DOCS=
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
		-d|--doc|--documents)
			MAKE_DOCS=Yes
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
pip install --upgrade \
	pip \
	build \
	pytest \
	pytest-cov \
	pytest-mock \
	setuptools \
	wheel

# create the package structure

TEMPLATE_DIR=${CMD_DIR}/templates

mkdir -p src/${PACKAGE_NAME} tests

cp ${TEMPLATE_DIR}/* .
mv gitignore .gitignore
cp ${TEMPLATE_DIR}/src/* src/${PACKAGE_NAME}
cp ${TEMPLATE_DIR}/tests/* tests

if [[ -n $MAKE_DOCS ]]; then
	cp ${TEMPLATE_DIR}/sphinx/index.rst .
fi

TEMPLATE_FILES=$(find . \
					  -path ./env -prune -o \
					  -path ./.git -prune -o \
					  -type f -print)


for f in $TEMPLATE_FILES; do
	for p in "PackageName|${PACKAGE_NAME}" \
				 "AuthorName|${AUTHOR_NAME}" \
				 "Email|${EMAIL_ADDRESS}" \
				 "VersionNumber|${VERSION}" \
				 "Repository|${REPOSITORY}"; do
		perl -pi -e "s|replaceWith${p}|g" $f
	done
done

python -m build --no-isolation .

python -m pip install --editable .

if [[ -n $MAKE_DOCS ]]; then

	DOC_DIR=sphinx

	pip install --upgrade \
		numpydoc \
		sphinx

	sphinx-quickstart ${DOC_DIR} \
					  --no-sep \
					  -l en \
					  -p ${PACKAGE_NAME} \
					  -a "${AUTHOR_NAME}" \
					  -r "${VERSION}" \
					  --ext-autodoc \
					  --ext-doctest \
					  --ext-intersphinx \
					  --extensions=numpydoc,sphinx.ext.autosummary

	mv index.rst ${DOC_DIR}

	echo \
		$(cat \
			  ${DOC_DIR}/conf.py \
			  ${TEMPLATE_DIR}/sphinx/extras_for_conf.py) \
		> ${DOC_DIR}/conf.py

	python setup.py build_sphinx

fi

python -m pip freeze > REQUIREMENTS.txt

deactivate

git add -A .
git commit -m "initialized package ${PACKAGE_NAME}"
git branch -M main

if [[ -n $REPOSITORY ]]; then
	git remote add origin $REPOSITORY
	git push -u origin main
fi
