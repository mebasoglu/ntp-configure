## NTP Configuration Script

This Bash script simplifies the configuration of NTP (Network Time Protocol) settings on Ubuntu-based GNU/Linux systems. It provides options for both configuring an NTP server and an NTP client.


### Features

- Supports configuring NTP servers and clients.
- Ability to specify custom remote NTP servers.
- Automated installation of the NTP package if not already installed.
- Disables systemd-timesyncd when configuring an NTP server.

### Prerequisites

- An Ubuntu-based GNU/Linux system.
- BASH (usually pre-installed on GNU/Linux systems).

### Usage

1. Clone this repository or download the script (ntp-config.sh) to your local machine.

2. Open a terminal and navigate to the directory containing the script.

3. Run the script with the desired command and arguments. See Usage Examples for more details.

### Commands

The script supports the following commands:

- `server-configure`: Configure the system as an NTP server.
- `client-configure <server_ip>`: Configure the system as an NTP client, specifying the NTP server's IP address.
- `--help` or `-h`: Display usage information.

### Examples
#### Configure an NTP Server

```bash
./ntp-config.sh server-configure
```

To configure an NTP server with custom remote NTP servers:

```bash
./ntp-config.sh server-configure --remote-ntp-servers "2.tr.pool.ntp.org 0.europe.pool.ntp.org 3.europe.pool.ntp.org"
```

#### Configure an NTP Client

```bash
./ntp-config.sh client-configure 172.17.0.3
```

### License

This script is released under the MIT License.