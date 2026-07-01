# Meshtastic Environment Monitoring with RAK6421 WisMesh Pi HAT

Transform your Raspberry Pi 4B/5 + RAK 6421 WisMesh Pi HAT + RAK Wisblock sensors into a Meshtastic-powered environment monitoring station with real-time visualization.

![Grafana Dashboard](assets/grafana_dashboard_measurements.png)

---

## 📋 Table of Contents

### For All Users
- [📖 What This Guide Provides](#-what-this-guide-provides)
- [1. Hardware Preparation](#1-hardware-preparation)
- [2. Software Preparation](#2-software-preparation)
- [3. Quick Start - Use Meshtastic Web Client](#3-quick-start---use-meshtastic-web-client) ⭐ **Start here!**  
  - [Power on and network access (RAK Pi OS image)](#power-on-and-network-access-rak-pi-os-image)

### For Advanced Users (Optional)
- [4. Advanced Setup - Add Visualization Dashboard](#4-advanced-setup---add-visualization-dashboard-optional)
  - [Option A: One-Command Installation](#option-a-one-command-installation)
  - [Option B: Step-by-Step Installation](#option-b-step-by-step-installation)
- [5. Post-Installation Configuration](#5-post-installation-configuration)
- [6. Verify Installation](#6-verify-installation)
- [7. Troubleshooting](#7-troubleshooting)
  - [Frequently asked questions (FAQ)](#frequently-asked-questions-faq)

---

## 📖 What This Guide Provides

### Two Usage Modes

**🚀 Quick Start (Recommended for Beginners)**
- Use Meshtastic web client directly - no installation needed
- Standard firmware includes meshtasticd service pre-installed
- Basic LoRa messaging and sensor data ready to use
- Perfect for users who just want to get started quickly

**📊 Advanced Setup (Optional - For Visualization)**
- Add Grafana dashboard for real-time monitoring
- Historical data storage with InfluxDB
- MQTT integration for automation
- Choose between one-command or step-by-step installation

### Complete Feature List

When using the full monitoring stack, you will get:
- Environment telemetry collection (temperature, humidity, pressure, air quality)
- GPS location services
- Real-time Grafana dashboards
- MQTT integration for automation
- Historical storage in InfluxDB

### Architecture Overview (For Advanced Setup)

When you add the visualization stack, data flows through this chain:

`Sensors -> meshtasticd -> MQTT (Mosquitto) -> Node-RED -> InfluxDB -> Grafana`

```text
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   RAK1906/1901  │────▶│   meshtasticd   │────▶│   Mosquitto     │
│   Environment   │ I2C │        Daemon   │MQTT │   MQTT Broker   │
│     Sensors     │     │  (Pre-installed)│     │   Port 1883     │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     Grafana     │◀────│    InfluxDB     │◀────│    Node-RED     │
│  Visualization  │Query│  Time-series DB │Write│   JSON Parser   │
│   Port 3000     │     │   Port 8086     │     │   Port 1880     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 1. Hardware Preparation

<img src="assets/RAK6421.jpg" alt="RAK6421 Pi HAT" style="zoom: 33%;" />

### RAK6421 Role in This Build

The RAK6421 WisMesh Pi HAT is the hardware integration layer for Raspberry Pi Meshtastic nodes:
- **Hardware layer:** connects Pi GPIO to LoRa radio module and I2C sensors
- **Software layer:** works with `meshtasticd` on Linux
- **Gateway layer:** can forward telemetry into MQTT/Node-RED/InfluxDB/Grafana

### Assembly

To assemble the board on top of Raspberry Pi:
- Mount modules/sensors to the HAT first and secure with screws
- Keep host powered off and unplugged during assembly
- Use spacers to keep proper distance/alignment between boards

<img src="assets/rak6421-assembly.png" alt="RAK6421 Pi HAT assembly" style="zoom:33%;" />

### Slot Layout

The RAK6421 WisBlock Pi HAT provides **2 IO slots** and **4 sensor slots**:
- **IO Slots (1 & 2):** LoRa radio modules such as **RAK13300** or **RAK13302**
- **Sensor Slot A:** larger slot for **RAK12501** GNSS module
- **Sensor Slots B/C/D:** environmental sensors such as **RAK1901**, **RAK1906**

> **Note:** Slot pin layouts differ. See the [RAK6421 WisBlock Pi HAT Datasheet](https://docs.rakwireless.com/product-categories/wishat/rak6421-wisblock-pi-hat/datasheet/#schematics).

### Meshtasticd-Supported WisBlock Modules
> **Compatibility note:** This document targets **meshtasticd 2.7.20**.  The following WisBlock modules have been tested and work with meshtasticd (as of version 2.7.20). We will update this list as new versions are released:

| RAK Name   | Chip / Component   | slot | Measures              | Status  |
|------------|--------------------|-----------------------|---------|---------|
| RAK13300   | Semtech SX1262  | IO slots (1 &2) | LoRa module            | Yes     |
| RAK13302   | Semtech SX1262, SKY66122 signal booster | IO slots (1 &2) | LoRa module           | Yes     |
| RAK12002   | Micro Crystal RV-3028-C7 | Sensor slot B/C/D | RTC             | Yes     |
| RAK12003   | Melexis MLX90632   | Sensor slot B/C/D | IR Temperature        | Yes     |
| RAK12019   | Lite On LTR-390UV-01 | Sensor slot B/C/D | UV sensor           | Yes     |
| RAK12020   | AMS TSL25911FN     | Sensor slot B/C/D | Ambient light         | Yes     |
| RAK12037   | Sensirion SCD30    | IO slot 1 only | CO2                   | PR ongoing |
| RAK12501   | Quectel L76K   | Sensor slot A |  GNSS GPS Location         | Yes |
| RAK1902    | STMicro LPS22HB    | Sensor slot B/C/D | Barometric Pressure   | Yes   |
| RAK1901    | Sensirion SHTC3   | Sensor slot B/C/D | Temp, Humidity   | Yes |
| RAK1906    | BME680             | Sensor slot B/C/D | Temperature, Humidity, Pressure, VOC gas sensing | Yes  |

### HAT EEPROM Auto-Discovery

RAK6421 includes onboard EEPROM so meshtasticd can auto-detect board info.
If you use your own Raspberry Pi image, ensure EEPROM detection is enabled in `/boot/firmware/config.txt`:

```bash
# Enable I2C-0 bus for HAT EEPROM
dtparam=i2c_vc=on
dtoverlay=i2c0
```

A reboot is required. If you use the [RAKwireless-provided image](https://github.com/RAKWireless/meshtastic-rak6421-guide/releases), this is already configured, you can ignore this.

---

## 2. Software Preparation

### Prerequisites

| Requirement | Details |
|-------------|---------|
| **Hardware** | Raspberry Pi 4 or Raspberry Pi 5 |
| **Raspberry Pi Image** | See [Firmware options](#firmware-options) below |
| **Hat** | RAK6421 WisMesh Pi HAT|
| **Sensors and radio module** | Sensor modules( e.g., RAK1906, RAK1901) + LoRa radio module(e.g., RAK13300, RAK13302) |

### Firmware Options

**🎯 Recommended: RAKwireless Official Image (Ready to Use)**

Use the dedicated [Meshtastic firmware from RAKwireless](https://github.com/RAKWireless/meshtastic-rak6421-guide/releases), which includes:
- **meshtasticd pre-installed and configured**
- Ready for RAK6421 HAT
- Optimized for Raspberry Pi 4/5
- Based on [pi-gen](https://github.com/RPi-Distro/pi-gen)

> **Default login (RAK Pi OS image)**  
> The pre-built image uses the account **`rak`** with default password **`changeme`**. You will be prompted to change this password on first login. Pick a strong password and keep it somewhere safe.

> 💡 **This is the easiest option** - flash the image, boot, and start using Meshtastic immediately via web client.

**Alternative Options (For Advanced Users)**

| Option | Description |
|--------|-------------|
| **Meshtastic Linux docs** | Follow the [Meshtasticd Linux installation](https://meshtastic.org/docs/software/linux/installation/) to install meshtasticd on your preferred distro (e.g. Raspberry Pi OS). You manage the base system yourself. |
| **mPWRD OS (Armbian)** | Build a custom Armbian image with Meshtastic integration using [mPWRD-userpatches](https://github.com/mPWRD-OS/mPWRD-userpatches) (Armbian + Meshtastic). Use `config-raspberry-pi-64bit.conf` for Raspberry Pi. |

---

## 3. Quick Start - Use Meshtastic Web Client

> ✅ **The standard RAKwireless firmware includes meshtasticd service** - it's already running when you boot!

### Before you start

1. Flash the [Meshtastic firmware from RAKwireless](https://github.com/RAKWireless/meshtastic-rak6421-guide/releases) to your SD card
2. Assemble the RAK6421 HAT with LoRa radio (RAK13300/RAK13302) and sensors
3. **Important:** Connect the antenna to the LoRa radio before powering on
4. Insert SD card, power on your Raspberry Pi

### Power on and network access (RAK Pi OS image)

The RAKwireless image can reach your LAN over Ethernet or Wi-Fi. How you power it on determines which path applies.

**Wired (Ethernet)**

- The image runs **DHCP on Ethernet** by default. Connect the Raspberry Pi to your router with a cable, then open your router’s admin page and find the DHCP lease / client list for the device.
- If you are validating the stack over Ethernet in the lab, you can **skip Wi-Fi setup** and go straight to [Step 2: Open Meshtastic Web Client](#step-2-open-meshtastic-web-client) once you know the IP address.

**Wireless (Wi-Fi and the configuration hotspot)**

- If you are **not** using Ethernet, power the board with a suitable power supply (official or adequate DC supply for your Pi model).
- When the Meshtastic station has **no working network** (no Ethernet link **and** no Wi-Fi client connection), the firmware starts a temporary **Configuration access point** so you can join it from a PC or phone and enter your Wi‑Fi credentials.

**Connecting to the configuration hotspot**

- The hotspot is **only for initial setup**. After the station joins your Wi‑Fi or uses Ethernet, the configuration AP **stops** broadcasting.
- **SSID:** `RAK_XXXX`, where **`XXXX`** is the **last four characters** of the device’s MAC address (hex digits).
- **Password:** `rakwireless`

> **Note (Windows 10/11)**  
> The Wi‑Fi dialog may default to **“Enter a PIN”** (WPS). The configuration hotspot uses **WPA2 with a passphrase**, not WPS. An eight‑digit WPS PIN is **not** the network password. To connect successfully, choose **“Connect using a security key”** / **“Enter the network security key”** (wording varies by build) and type **`rakwireless`**. Do **not** use the WPS PIN field for this network.

After the station is on your LAN, continue with the steps below.

### Open the Meshtastic web client

#### Step 1: Find Your Pi's IP Address

Check your router's DHCP client list, or connect a monitor/keyboard to the Pi and run:
```bash
hostname -I
```

#### Step 2: Open Meshtastic Web Client

From any device on the same network, open: `https://<Pi-IP>:9443`

Example: `https://192.168.1.100:9443`

#### Step 3: Connect to Your Node

1. Click **"+ New Connection"**

   ![Meshtastic Web Client - Add Device](assets/meshtastic_web_client_add_device.png)

2. Select **HTTP**, enter `<Pi-IP>:9443`, then click **Connect**

   ![Meshtastic Web Client - Connect](assets/meshtastic_web_client_connect_to_new_device.png)

3. Go to **Config** -> **Radio Config** -> **LoRa** to verify and configure settings

   ![Meshtastic Web Client - Radio Config](assets/meshtastic_web_client_radio_config.png)

#### Step 4: Start Using Meshtastic!

You can now:
- Configure your node name and settings
- Join mesh networks
- Send messages
- View sensor data in the Messages tab
- Configure telemetry intervals

### Alternative Connection Methods

#### Option A: Meshtastic Mobile App

Download the Meshtastic app on iOS or Android, then connect using the Pi's IP address (ensure phone and Pi are on the same local network).

#### Option B: Meshtastic Python CLI

SSH into your Pi (see [FAQ](#frequently-asked-questions-faq) if SSH is not enabled yet) and use the meshtastic python cli, for example:

```bash
meshtastic --info
```

### What's Next?

**🎉 You're Done!** Your Meshtastic node is fully functional.

**Want Advanced Visualization?** 
- If you're happy with the web client, you can stop here
- If you want Grafana dashboards, historical data, and MQTT integration, continue to Section 4 below

---

## 4. Advanced Setup - Add Visualization Dashboard (Optional)

> ⚠️ **This section is optional** - only follow these steps if you want Grafana dashboards and historical data storage.

### Why Add the Visualization Stack?

The basic Meshtastic web client shows current data, but if you want:
- **Real-time dashboards** with graphs and charts
- **Historical data** stored in a database
- **MQTT integration** for automation
- **Multi-node visualization** on one dashboard

...then continue with this advanced setup.

### Before You Begin

First, clone this repository to get the installation scripts:

```bash
git clone https://github.com/RAKWireless/meshtastic-rak6421-guide.git
cd meshtastic-rak6421-guide
```

### Choose Your Installation Method

**Option A: One-Command Installation (Recommended)** → [Jump to instructions](#option-a-one-command-installation)

**Option B: Step-by-Step Installation (For Advanced Users)** → [Jump to instructions](#option-b-step-by-step-installation)

Both methods install the same components. After installation, continue with [Post-Installation Configuration](#5-post-installation-configuration).

---

### Option A: One-Command Installation

The fastest way to add visualization is to run the complete installation script:

```bash
cd setup/scripts
./install-all.sh
```

This script installs all components in the correct order and takes approximately 20-30 minutes (depending on your network speed).

**What Gets Installed:**
1. Meshtastic CLI
2. Mosquitto MQTT Broker (for message routing)
3. Configure telemetry settings
4. InfluxDB (time-series database)
5. Node-RED (data processing)
6. Grafana (visualization dashboard)

> **Tip:** Before running the installation, you can customize credentials in `setup/config/credentials.env`

```bash
# InfluxDB Configuration
INFLUXDB_USERNAME="admin"
INFLUXDB_PASSWORD="your_secure_password"
INFLUXDB_ORG="meshtastic"
INFLUXDB_BUCKET="meshtastic"

# Grafana Configuration
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="your_secure_password"
```

After installation completes, skip to [Section 5: Post-Installation Configuration](#5-post-installation-configuration).

---

### Option B: Step-by-Step Installation

If you prefer to install components individually or need more control, follow these steps.

**Before running any scripts**, ensure you're in the scripts directory:
```bash
cd setup/scripts
```

Each script can be run independently. The scripts install their own dependencies, so you can run any step by itself if needed.

#### Step 1: Meshtastic CLI

```bash
./01-install-meshtastic-cli.sh
```

This install `pipx` and `meshtastic-cli` for future steps to use for configuring the radio

#### Step 2: Configure Serial Port (Optional)

```bash
./02-configure-serial.sh
```

This configures the serial port for the Meshtastic GPS module (UART enabled, serial console disabled) and also updates `/etc/meshtasticd/config.yaml` by **uncommenting** common required lines (only if they are currently commented), including:
- `GPS.SerialPath`: The script automatically detects your Raspberry Pi version and sets the correct device:
  - **Raspberry Pi 5**: `/dev/ttyAMA0`
  - **Raspberry Pi 4**: `/dev/ttyS0`
- `I2C.I2CDevice: /dev/i2c-1`
- `Webserver.Port: 9443`

A reboot is required for changes to take effect.

> **Important for Manual Configuration:** If you prefer to edit `/etc/meshtasticd/config.yaml` manually instead of running this script, note that the GPS serial path differs between Raspberry Pi models:
> - **Raspberry Pi 5**: Use `SerialPath: /dev/ttyAMA0`
> - **Raspberry Pi 4**: Use `SerialPath: /dev/ttyS0`

If you'd rather make these edits yourself, see [`config.yaml`](./config.yaml) in this repository for an example configuration.

#### Step 3: Install Mosquitto MQTT Broker

```bash
./03-install-mosquitto.sh
```

The MQTT broker receives messages from meshtasticd on port 1883.

> **Note:** Install the MQTT broker first before configuring telemetry settings. The Meshtastic device needs a working MQTT broker connection to successfully apply MQTT-related configurations.

#### Step 4: Configure Telemetry & MQTT

```bash
./04-configure-telemetry.sh
```

This script will use the Meshtastic Python CLI to configure:
- Environment telemetry (sensor data collection)
- GPS/position mode and broadcast settings
- MQTT: enabled, broker address (default `localhost`), JSON output enabled
- Channel 0 uplink enabled (required for MQTT publishing)

> **Important:** Before running this script, ensure your MQTT broker is running and accessible. The script will configure MQTT settings on your Meshtastic device, which requires a working MQTT connection. If you use a remote MQTT broker instead of the local one from Step 2, edit the script to set the correct MQTT address, or configure it manually as described below.

**If you configure manually** (via the Meshtastic web client, mobile app, or Python CLI instead of this script), you must enable the same options:
- **MQTT:** enable MQTT, set the broker address (e.g. `localhost` or your remote broker), enable JSON packets
- **Channel 0:** enable uplink for the primary channel (e.g. with the CLI: `meshtastic --ch-set uplink_enabled true --ch-index 0`)
- **Telemetry:** enable environment measurement and set update interval as needed
- **Position:** set GPS mode and position broadcast options as needed 

#### Step 5: Install InfluxDB

```bash
./05-install-influxdb.sh
```

This script installs InfluxDB as a system service, creates the organization and bucket for Meshtastic data, and configures the admin account. Node-RED will write telemetry to this database; Grafana will read from it.

Default configuration:
| Setting | Value |
|---------|-------|
| Username | admin |
| Password | meshtastic |
| Organization | meshtastic |
| Bucket | meshtastic |

> **Note:** You can customize these in `config/credentials.env` before installation.

#### Step 6: Install Node-RED

```bash
./06-install-nodered.sh
```

This script installs Node.js (20 LTS) and Node-RED using the official installer, applies the project's custom [settings.js](setup/nodered/settings.js), and enables the Node-RED system service. After installation you will configure the InfluxDB token in Node-RED (see [Section 5: Post-Installation Configuration](#5-post-installation-configuration)).

> **Important:** This step takes 20-30 minutes on slower Pi models.

#### Step 8: Install Grafana

```bash
./08-install-grafana.sh
```

This script adds the Grafana APT repository, installs Grafana, enables the service, and provisions the InfluxDB data source. A pre-configured dashboard is deployed so you can view Meshtastic data without manual setup: it displays **environment telemetry** (temperature, humidity, pressure, air quality / IAQ, light and UV) and **GPS/position** (satellite count, PDOP, track, and map). After installation, open **Dashboards** → **Meshtastic** → **Meshtastic Environment Monitor** in Grafana. The dashboard definition is in [setup/grafana/dashboard.json](setup/grafana/dashboard.json) if you want to customize or inspect it.

Default configuration:
| Setting | Value |
|---------|-------|
| Admin user | admin |
| Admin password | admin |

> **Note:** You can customize these in `config/credentials.env` before installation. 

---

## 5. Post-Installation Configuration

### Configure Node-RED InfluxDB Token

After installation, you need to configure the InfluxDB token in Node-RED:

**1. Get the token:**
```bash
./show-token.sh
```

**2. Open Node-RED** at `http://<Pi-IP>:1880` (from any device on your LAN)

**3. Double-click the "Write to InfluxDB" node:**

![Edit InfluxDB Node](assets/edit_influxdb_node.png)

**4. Click the pencil icon next to "Local InfluxDB" and paste the token:**

![Enter Token](assets/enter_token.png)

**5. Click "Update", then "Done", then click "Deploy":**

![Deploy Flow](assets/deploy_flow.png)

---

## 6. Verify Installation

### Check Service Status

```bash
rak@rakpios:~/setup/scripts $ ./check-services.sh 
==========================================
Meshtastic Monitoring System Service Status
==========================================

--- Meshtastic Daemon ---
✓ meshtasticd is running

--- MQTT Broker ---
✓ Mosquitto is running
  URL: http://<Pi-IP>:1883

--- Node-RED ---
✓ Node-RED is running
  URL: http://<Pi-IP>:1880

--- InfluxDB ---
✓ InfluxDB is running
  URL: http://<Pi-IP>:8086

--- Grafana ---
✓ Grafana is running
  URL: http://<Pi-IP>:3000

==========================================
MQTT Test
==========================================
mosquitto_sub not installed, skipping MQTT test

==========================================
Port Listening Status
==========================================
MQTT (1883):
LISTEN 0      100          0.0.0.0:1883      0.0.0.0:*                                       
Node-RED (1880):
LISTEN 0      511          0.0.0.0:1880      0.0.0.0:*    users:(("node-red",pid=2839,fd=19))
InfluxDB (8086):
LISTEN 0      4096               *:8086            *:*                                       
Grafana (3000):
LISTEN 0      4096               *:3000            *:*                                       

==========================================
Quick Access Links
==========================================
Node-RED:  http://10.2.13.62:1880
InfluxDB:  http://10.2.13.62:8086
Grafana:   http://10.2.13.62:3000
```

### Access URLs

Access these services from any device on your LAN using `http://<Pi-IP>:<port>`, where `<Pi-IP>` is your Raspberry Pi's IP address.

| Service | URL | Default Login |
|---------|-----|---------------|
| Node-RED | `http://<Pi-IP>:1880` | - |
| InfluxDB | `http://<Pi-IP>:8086` | admin / meshtastic |
| Grafana | `http://<Pi-IP>:3000` | admin / admin |

### View Dashboard

1. Open Grafana at `http://<Pi-IP>:3000`
2. Login with admin / admin
3. Navigate to **Dashboards** → **Meshtastic** folder
4. Click **Meshtastic Environment Monitor**

![Grafana Dashboard](assets/grafana_dashboard.png)

---

## 7. Troubleshooting

### Frequently asked questions (FAQ)

**I changed the LoRa region in the Meshtastic web UI and now I see odd behavior (for example I can send packets but not receive).**  
Try **restarting the device** (power-cycle the Raspberry Pi or reboot from the terminal). Region and radio timing changes sometimes need a full restart to apply cleanly.

**The time shown in the Meshtastic web UI is wrong.**  
Connect your *WisMesh station* (including **Raspberry Pi 4**) to a network over **Ethernet or Wi‑Fi** so the operating system can synchronize the clock from **NTP** time servers. After the system time is correct, refresh the web client; the displayed time should match.

**I want to use SSH, but it is not available.**  
On the current RAK Pi OS image, **SSH is not enabled by default**. Connect a **display and keyboard**, log in locally, and run `sudo raspi-config`, then enable SSH under the interface options. **A future image release is planned to ship with SSH enabled by default;** until then, use `raspi-config` after first boot.

### No MQTT Messages?

1. Check if meshtasticd is running:
   ```bash
   systemctl status meshtasticd
   ```

2. Verify MQTT is enabled:
   ```bash
   meshtastic --get mqtt.enabled
   ```

3. Test MQTT subscription (run on the Pi or from another machine on the LAN):
   ```bash
   mosquitto_sub -h <Pi-IP> -t 'msh/#' -v
   ```

### Node-RED Can't Connect to InfluxDB?

1. Verify InfluxDB is running:
   ```bash
   systemctl status influxdb
   ```

2. Check the token is correct in Node-RED

3. Verify organization name matches (default: "meshtastic")

### Grafana Shows No Data?

1. Check data source configuration:
   - Go to **Connections** → **Data Sources** → **InfluxDB**
   - Click **Save & Test**

2. Verify data is being written:
   - Open InfluxDB UI at `http://<Pi-IP>:8086`
   - Go to **Data Explorer**
   - Query the "meshtastic" bucket
   ![InfluxDB data explorer](assets/influxdb_data_explorer.png)

3. Check Node-RED debug output for errors

### Sensor Data Not Updating?

1. Check sensor connection:
   ```bash
   i2cdetect -y 1
   ```
   Should show address 0x76 for RAK1906（BME680）and 0x70 for RAK1901(SHTC3)

2. View meshtasticd logs:
   ```bash
   journalctl -u meshtasticd -f
   ```

### GPS Module Not Working?

Use minicom to check whether the GPS is outputting NMEA data on the serial port (install minicom if needed):

1. Install minicom:
   ```bash
   sudo apt-get install -y minicom
   ```

2. Connect to the GPS serial device at 9600 baud. Use the device that matches your Pi and setup:
   - **Raspberry Pi 4:** `/dev/ttyS0`
   - **Raspberry Pi 5:** `/dev/ttyAMA0`

   ```bash
   sudo minicom -D /dev/ttyS0 -b 9600
   ```
   Replace `/dev/ttyS0` with `/dev/ttyAMA0` as appropriate.

3. You should see NMEA sentences (lines starting with `$GP...`) if the GPS is working. Exit minicom with **Ctrl+A**, then **Z** (Opens the Help Screen),**Q** (quit), and finally **Enter**.

### Service Management

```bash
# Restart all services
sudo systemctl restart mosquitto nodered influxdb grafana-server

# View logs
journalctl -u meshtasticd -f
journalctl -u nodered -f
...

# Check status
setup/scripts/check-services.sh
```

---


## References

- [meshtasticd Linux installation](https://meshtastic.org/docs/software/linux/installation/)
- [Meshtastic Web client](https://meshtastic.org/docs/software/web-client/)
- [Meshtastic Python CLI](https://meshtastic.org/docs/software/python/cli/)
- [Meshtastic Position Configuration](https://meshtastic.org/docs/configuration/radio/position/)
- [Meshtastic Telemetry Configuration](https://meshtastic.org/docs/configuration/module/telemetry/)
- [meshtasticd MQTT Configuration](https://meshtastic.org/docs/configuration/module/mqtt/)

