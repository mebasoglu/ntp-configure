#! /usr/bin/env bash

# MIT License

# Copyright (c) 2023 Mehmet Emin BAŞOĞLU

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Emojis
CHECK='\U2705'
GRIMACING_FACE='\U1F62C'

usage() {
    echo "Usage: $0 [-h] [--help] <command> [args]"
    echo
    echo "Commands:"
    echo -e "\t server-configure"
    echo -e "\t client-configure"
    echo
    echo

    echo "The \"ntp\" package in Ubuntu comes with default Ubunu NTP pools."
    echo "To create a server with default NTP pools:"
    echo
    echo -e "${BOLD}$ $0 server-configure${NC}"
    echo
    echo

    echo "https://ntppool.org offers NTP servers all around the world."
    echo "You can find a list of servers in Turkey here: https://www.pool.ntp.org/zone/tr"
    echo "To create a server with custom remote NTP servers add \"--remote-ntp-servers\" "
    echo "optional parameter and enter your addresses in \"\" with space seperated."
    echo
    echo -e "${BOLD}$ $0 server-configure --remote-ntp-servers \"2.tr.pool.ntp.org 0.europe.pool.ntp.org 3.europe.pool.ntp.org\"${NC}"
    echo
    echo

    echo "To configure a client, you need the address of the server:"
    echo
    echo -e "${BOLD}$ $0 client-configure 172.17.0.3${NC}"

}

invalid_args() {
    usage
    echo -e "${RED}Invalid argument.${NC} ${GRIMACING_FACE}"
}

check_sudo() {
    if hash sudo 2>/dev/null; then
        echo "Found sudo."
        SUDO=sudo
    else
        echo "Couldn't find sudo."
        SUDO=""
    fi
}

install-packages() {
    dpkg -l | grep ntp >/dev/null
    EXIT_CODE=$?

    if [ ${EXIT_CODE} -eq 0 ]; then
        echo -e "${BLUE}Ntp is already installed.${NC}"
        return 0
    fi

    echo -e "${BLUE}Installing ntp.${NC}"

    ${SUDO} apt-get update
    # ${SUDO} apt-get upgrade -y
    ${SUDO} apt-get install -y ntp

    echo -e "${GREEN}Installed ntp.${NC}"
}

disable_timesyncd() {
    if hash "timedatectl" 2>/dev/null; then
        # Found command.
        # We need to disable systemd-timesyncd because we use ntpd.
        ${SUDO} timedatectl set-ntp no
        echo -e "${GREEN}Disabled timesyncd.${NC}"
    fi
}

server-configure() {
    install-packages
    disable_timesyncd

    if [ -n "$1" ]; then
        echo bura
        # User specified remote servers.
        # Parse remote servers.
        IFS=' ' read -a ntp_servers <<<"$1"

        # Comment out default NTP pools.
        ${SUDO} sed 's/^pool/#&/' /etc/ntp.conf -i

        # Add NTP servers.
        for f in "${ntp_servers[@]}"; do
            # Server may already be in the config, check it.
            grep "$f" /etc/ntp.conf >/dev/null
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 0 ]; then
                echo -e "${BLUE}$f already exists in config file.${NC}"
                continue
            fi

            printf 'server %s iburst' "$f" | ${SUDO} tee -a /etc/ntp.conf
            echo | ${SUDO} tee -a /etc/ntp.conf
        done

        echo -e "${GREEN}Configured remote servers.${NC}"

    fi

    # In case of losing Internet connectivity, use local clock as default.
    grep "server 127.127.1.0" /etc/ntp.conf >/dev/null
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -eq 1 ]; then
        echo "server 127.127.1.0" | ${SUDO} tee -a /etc/ntp.conf
    fi

    grep "fudge 127.127.1.0 stratum 10" /etc/ntp.conf >/dev/null
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -eq 1 ]; then
        echo "fudge 127.127.1.0 stratum 10" | ${SUDO} tee -a /etc/ntp.conf
    fi

    echo -e "${GREEN}Set local clock as default.${NC}"

    # Restart NTP deamon.
    ${SUDO} service ntp restart

    echo -e "${BLUE}Waiting for some time to communicate with peers.${NC}"

    # Wait for some time to sync peers.
    sleep 5

    # Verbose NTP peers.
    ntpq -p

    echo
    echo -e "${CHECK}${GREEN} Server is configured.${NC}"
}

client-configure() {
    install-packages
    disable_timesyncd

    # Comment out default NTP pools.
    ${SUDO} sed 's/^pool/#&/' /etc/ntp.conf -i

    grep "server $1 iburst" /etc/ntp.conf >/dev/null
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -eq 1 ]; then
        # Add local NTP server.
        echo "server $1 iburst" | ${SUDO} tee -a /etc/ntp.conf
    fi

    echo -e "${GREEN}Set local NTP server.${NC}"

    # Restart NTP deamon.
    ${SUDO} service ntp restart

    echo -e "${BLUE}Waiting for some time to communicate with peers.${NC}"

    # Wait for some time to sync peers.
    sleep 5

    # Verbose NTP peers.
    ntpq -p

    echo
    echo -e "${CHECK}${GREEN} Client is configured.${NC}"
}

main() {
    check_sudo

    if [ "$1" = server-configure ]; then

        # Optional argument.
        if [ "$2" = "--remote-ntp-servers" ]; then
            # User entered remote servers.
            server-configure "$3"
        elif [ "$2" = "" ]; then
            # No remote servers provided, use defaults.
            server-configure
        else
            invalid_args
        fi

    elif [ "$1" = client-configure ]; then

        if [ "$2" = "" ]; then
            invalid_args
        else
            client-configure "$2"
        fi

    elif [ "$1" = "--help" ]; then
        usage

    elif [ "$1" = "-h" ]; then
        usage

    else
        # Print usage if no parameter is provided.
        invalid_args
    fi
}

main "$@"
