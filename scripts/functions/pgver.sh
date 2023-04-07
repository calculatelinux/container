#!/bin/bash

set -ueo pipefail

arg=${1:-}
ver=$(ls -d /var/db/pkg/dev-db/postgresql-*); ver=${ver##*-}

if [[ "$arg" == slot ]]; then
	echo ${ver%%.*}
else
	echo ${ver%%-*}
fi
