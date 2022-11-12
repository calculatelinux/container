#!/bin/bash

set -ueo pipefail

/var/db/repos/container/scripts/taiga-postgresql.sh

/var/db/repos/container/scripts/taiga-rabbitmq.sh

su - taiga -c '/var/db/repos/container/scripts/taiga-www-install.sh'

/var/db/repos/container/scripts/taiga-www-setup.sh

su - taiga -c '/var/db/repos/container/scripts/taiga-www-migrate.sh'

rc-update add taiga
rc-update -u
openrc
