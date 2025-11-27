# UFW Blocklist Enhanced Edition v2.0

Advanced Ubuntu firewall protection with threat intelligence and geographic IP blocking capabilities.

## 🌟 New Features

### **Dual IP Source Support**
- **Threat Intelligence**: Malicious IP addresses from IPsum (13,000+ entries)
- **Geographic Blocking**: China IP ranges from ipdeny.com (8,000+ CIDR blocks)
- **Independent Updates**: Separate update frequencies for each source

### **Flexible Configuration**
- **Conservative Strategy**: Enable only threat blocking (default)
- **Complete Strategy**: Enable both threat and geographic blocking
- **User Choice**: Interactive configuration wizard

### **Enhanced Architecture**
- **Modular Design**: Support for multiple IP list modules
- **Atomic Updates**: Zero-downtime IP set replacements
- **Smart Logging**: Direction-aware logging with rate limiting

## 🚀 Quick Start

### Installation (One-Click)
```bash
# Download enhanced edition
git clone https://github.com/poddmo/ufw-blocklist.git
cd ufw-blocklist

# Run interactive installer
sudo ./install.sh

# Or non-interactive (threat blocking only)
sudo ENABLE_GEO_UPDATE=no ./install.sh

# Or full protection
sudo ENABLE_GEO_UPDATE=yes DEFAULT_STRATEGY=complete ./install.sh
```

### Configuration Management
```bash
# Interactive configuration wizard
sudo ufw-blocklist-config --interactive

# Show current configuration
sudo ufw-blocklist-config --show

# Reset to defaults
sudo ufw-blocklist-config --reset
```

## 📋 Comparison: Original vs Enhanced

| Feature | Original | Enhanced |
|---------|---------|---------|
| **Data Sources** | IPsum only | IPsum + ipdeny.com |
| **IP Format Support** | IPv4 only | IPv4 + CIDR notation |
| **Update Strategy** | Daily only | Daily/Weekly per source |
| **Configuration** | Manual editing | Interactive wizard |
| **Safety Default** | Full blocking | Conservative (threat only) |
| **Module Support** | Single script | Multiple IP set modules |
| **Backup Support** | Manual backup | Automatic backup |
| **User Choice** | Technical | User-friendly |

## 🔧 Advanced Configuration

### Configuration File Structure
```bash
# /etc/default/ufw-blocklist
THREAT_IPSET="ufw-blocklist-threat"      # Threat intelligence set
GEO_IPSET="ufw-blocklist-cn"            # Geographic blocking set
THREAT_URL="https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt"
GEO_URL="http://www.ipdeny.com/ipblocks/data/countries/cn.zone"
ENABLE_THREAT_UPDATE="yes"               # Enable/disable updates
ENABLE_GEO_UPDATE="no"                  # Default: conservative
THREAT_UPDATE_FREQ="daily"                # Update frequency
GEO_UPDATE_FREQ="weekly"                  # Update frequency
DEFAULT_STRATEGY="conservative"            # Safety strategy
```

### Dual IP Set Architecture
```bash
# Threat Intelligence (INPUT blocking)
ufw-blocklist-threat → ufw-blocklist-input → DROP

# Geographic Blocking (OUTPUT/FORWARD blocking)
ufw-blocklist-cn → ufw-blocklist-cn → LOG → DROP
```

### Update Frequency Options
- **Daily**: Maximum protection, higher overhead
- **Weekly**: Balance of protection and performance
- **Monthly**: Minimum overhead, may miss new allocations

## 🛡️ Usage Examples

### Basic Operations
```bash
# Standard UFW commands (still work)
sudo ufw enable                    # Enable firewall
sudo ufw disable                   # Disable firewall
sudo ufw status                     # Check status

# Enhanced commands
sudo /etc/ufw/after.init status    # Show blocklist statistics
sudo /etc/ufw/after.init flush-all # Clear all entries
sudo ufw-blocklist-config --show  # Show configuration
```

### Enabling Geographic Blocking
```bash
# Method 1: Reconfigure interactively
sudo ufw-blocklist-config --interactive
# Choose "Complete Strategy" when prompted

# Method 2: Manual configuration
sudo sed -i 's/ENABLE_GEO_UPDATE="no"/ENABLE_GEO_UPDATE="yes"/' /etc/default/ufw-blocklist
sudo /etc/ufw/after.init restart

# Method 3: One-time enable
ENABLE_GEO_UPDATE=yes sudo /etc/ufw/after.init start
```

### Custom Data Sources
```bash
# Add custom threat intelligence
THREAT_URL="https://your-threat-source.com/list.txt"
sudo ufw-blocklist-config --interactive

# Add custom geographic blocks
GEO_URL="https://your-geo-source.com/country.zone"
sudo ufw-blocklist-config --interactive
```

## 📊 Monitoring and Troubleshooting

### Status Monitoring
```bash
# Show detailed statistics
sudo /etc/ufw/after.init status

# Expected output:
Name: ufw-blocklist-threat
Type: hash:net
Number of entries: 13581
  76998  4403836 ufw-blocklist-input  all  --  *      0.0.0/0            0.0.0.0            match-set ufw-blocklist-threat src
   868  160 ufw-blocklist-output  all  --  *      0.0.0/0            0.0.0.0            match-set ufw-blocklist-cn dst
```

### Log Analysis
```bash
# View recent block events
sudo journalctl | grep -i blocklist | tail -20

# Common log patterns:
[UFW BLOCKLIST INPUT]    # Threat IP blocked (inbound)
[UFW BLOCKLIST OUTPUT]   # Attempt to reach geo-blocked IP (compromised host)
[UFW BLOCKLIST FORWARD]  # Internal host trying to reach geo-blocked IP
```

### Performance Monitoring
```bash
# Check ipset memory usage
sudo ipset list -t | grep -E "(Size|References)"

# Monitor update performance
sudo tail -f /var/log/syslog | grep ufw-blocklist
```

## 🔒 Security Considerations

### Risk Assessment
- **Threat Intelligence**: Low risk - well-vetted security sources
- **Geographic Blocking**: Medium risk - may block legitimate traffic
- **Combined Mode**: High protection - requires careful configuration

### Best Practices
1. **Start Conservative**: Enable only threat blocking initially
2. **Monitor Logs**: Check for false positives before enabling geo-blocking
3. **Test Services**: Verify legitimate services still work
4. **Update Regularly**: Keep threat intelligence current
5. **Backup Configuration**: Save working configurations

### Service Impact
- **Conservative Mode**: Minimal impact on legitimate services
- **Complete Mode**: May affect:
  - China-based cloud services
  - Chinese business partners
  - Academic/research collaborations
  - CDN services with China nodes

## 🔄 Migration from Original

### Backup Original Setup
```bash
# The installer automatically creates backups in:
/etc/ufw-backup-YYYYMMDD-HHMMSS/
```

### Migration Steps
1. **Install Enhanced Edition**: `sudo ./install.sh`
2. **Verify Configuration**: `sudo ufw-blocklist-config --show`
3. **Test Services**: Ensure legitimate services work
4. **Enable Additional Features**: Use configuration wizard
5. **Monitor Performance**: Check logs for issues

### Rollback Plan
```bash
# Restore original configuration if needed
sudo cp /etc/ufw-backup-*/after.init.backup /etc/ufw/after.init
sudo cp /etc/ufw-backup-*/ufw-blocklist-ipsum.backup /etc/cron.daily/ufw-blocklist-ipsum
sudo /etc/ufw/after.init restart
```

## 🧪 Testing Guide

### Functional Testing
```bash
# 1. Test threat blocking
curl -v http://known-malicious-ip.com
# Should timeout or be blocked

# 2. Test geographic blocking
# Enable geo-blocking first
ENABLE_GEO_UPDATE=yes sudo /etc/ufw/after.init restart
curl -v http://chinese-website.cn
# May be blocked depending on IP allocation

# 3. Test legitimate services
curl -v https://google.com
# Should work normally
```

### Performance Testing
```bash
# Measure update time
time sudo /etc/cron.daily/ufw-blocklist

# Test memory usage
sudo ipset list -t | grep "Size in memory"

# Check iptables performance
sudo iptables -L -nvx | head -20
```

## 📁 File Structure

### After Installation
```
/etc/
├── default/
│   └── ufw-blocklist          # Main configuration file
├── ufw/
│   ├── after.init               # Enhanced UFW integration
│   └── after.init.d/           # Module directory (for future)
├── cron.daily/
│   └── ufw-blocklist           # Enhanced update script
└── ufw/modules/                 # Module directory (for future)

/usr/local/bin/
└── ufw-blocklist-config          # Configuration manager

/usr/local/share/doc/ufw-blocklist/
├── README-ENHANCED.md          # This documentation
└── examples/                     # Configuration examples
```

### Configuration Templates
```bash
# Conservative configuration (default)
ENABLE_THREAT_UPDATE="yes"
ENABLE_GEO_UPDATE="no"
DEFAULT_STRATEGY="conservative"

# Complete protection configuration
ENABLE_THREAT_UPDATE="yes"
ENABLE_GEO_UPDATE="yes"
DEFAULT_STRATEGY="complete"

# Custom sources configuration
THREAT_URL="https://your-source.com/threats.txt"
GEO_URL="https://your-source.com/geo.zone"
```

## 🆘 Support and Troubleshooting

### Common Issues
1. **"ipset does not exist"**:
   - Run: `sudo /etc/ufw/after.init start`
   - Or enable UFW: `sudo ufw enable`

2. **"curl error downloading list"**:
   - Check internet connectivity
   - Verify URLs in configuration
   - Check firewall rules blocking downloads

3. **"High memory usage"**:
   - Reduce update frequency
   - Use conservative strategy
   - Monitor with: `sudo ipset list -t`

4. **"Legitimate services blocked"**:
   - Check logs: `sudo journalctl | grep blocklist`
   - Add specific IP ranges to whitelist
   - Consider disabling geographic blocking

### Getting Help
- **Configuration**: `sudo ufw-blocklist-config --interactive`
- **Status**: `sudo /etc/ufw/after.init status`
- **Logs**: `sudo journalctl | grep -i blocklist`
- **Community**: GitHub Issues at https://github.com/poddmo/ufw-blocklist

---

## 📄 License

Copyright 2013 Canonical Ltd.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.