
# Tomcat Application Deployment

Production deployment of Java web application on Apache Tomcat with custom configuration and systemd service management.

## 🎯 Challenge Overview

Install and configure Apache Tomcat application server, deploy a Java web application (WAR file), and ensure it runs reliably on a non-standard port with proper service management.

## 📋 Requirements

- Install Apache Tomcat on App Server 1
- Configure Tomcat to run on port 6200 (non-standard)
- Deploy ROOT.war application from Jump Host
- Application accessible at `http://stapp01:6200`
- Production-ready service management with systemd
- Security hardening (non-root execution)

## 🏗️ Architecture
```
┌─────────────────────────────────────────────┐
│         App Server 1 (stapp01)              │
├─────────────────────────────────────────────┤
│                                             │
│  ┌───────────────────────────────────┐     │
│  │  System Layer                     │     │
│  │  • Java OpenJDK 1.8               │     │
│  │  • Linux (CentOS/RHEL)            │     │
│  │  • User: tomcat (non-root)        │     │
│  └───────────────────────────────────┘     │
│                   ↓                         │
│  ┌───────────────────────────────────┐     │
│  │  Application Server               │     │
│  │  • Apache Tomcat 9                │     │
│  │  • Port: 6200                     │     │
│  │  • Location: /opt/tomcat/         │     │
│  └───────────────────────────────────┘     │
│                   ↓                         │
│  ┌───────────────────────────────────┐     │
│  │  Application                      │     │
│  │  • ROOT.war → ROOT/               │     │
│  │  • Auto-extracted                 │     │
│  └───────────────────────────────────┘     │
│                   ↓                         │
│  ┌───────────────────────────────────┐     │
│  │  Service Management               │     │
│  │  • systemd service                │     │
│  │  • Auto-start on boot             │     │
│  └───────────────────────────────────┘     │
│                                             │
└─────────────────────────────────────────────┘
                    ↓
            HTTP GET Request
          http://stapp01:6200
                    ↓
              200 OK Response
```

## 🛠️ Implementation

### Step 1: Install Java Runtime
```bash
# Switch to root
sudo su -

# Install Java OpenJDK 1.8
yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel -y

# Verify installation
java -version
# Output: openjdk version "1.8.0_xxx"
```

### Step 2: Install Apache Tomcat
```bash
# Create tomcat user (security best practice)
useradd -m -U -d /opt/tomcat -s /bin/false tomcat

# Download Tomcat 9 (stable version)
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz

# Extract archive
tar -xzf apache-tomcat-9.0.75.tar.gz

# Move to installation directory
mv apache-tomcat-9.0.75 /opt/tomcat/

# Create symbolic link for easier management
ln -s /opt/tomcat/apache-tomcat-9.0.75 /opt/tomcat/latest

# Set ownership
chown -R tomcat:tomcat /opt/tomcat/

# Make scripts executable
chmod +x /opt/tomcat/latest/bin/*.sh
```

### Step 3: Configure Custom Port
```bash
# Edit Tomcat server configuration
vi /opt/tomcat/latest/conf/server.xml

# Find this line (around line 69):
# <Connector port="8080" protocol="HTTP/1.1"

# Change to:
# <Connector port="6200" protocol="HTTP/1.1"
```

**Configuration snippet:**
```xml
<Connector port="6200" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />
```

### Step 4: Create Systemd Service
```bash
# Create service file
vi /etc/systemd/system/tomcat.service
```

**Service Configuration:**
```ini
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment="JAVA_HOME=/usr/lib/jvm/jre"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
```

### Step 5: Deploy Application
```bash
# Transfer WAR file from Jump Host
scp tony@jump_host:/tmp/ROOT.war /tmp/

# Remove default ROOT application
rm -rf /opt/tomcat/latest/webapps/ROOT

# Copy WAR to webapps directory
cp /tmp/ROOT.war /opt/tomcat/latest/webapps/

# Set ownership
chown tomcat:tomcat /opt/tomcat/latest/webapps/ROOT.war
```

### Step 6: Start Tomcat Service
```bash
# Reload systemd
systemctl daemon-reload

# Enable service (start on boot)
systemctl enable tomcat

# Start service
systemctl start tomcat

# Check status
systemctl status tomcat
```

## ✅ Verification

### Service Status
```bash
# Check if service is running
systemctl status tomcat

# Expected: Active: active (running)
```

### Port Listening
```bash
# Verify Tomcat is listening on port 6200
netstat -tulpn | grep 6200
# OR
ss -tulpn | grep 6200

# Expected: tcp6  0  0 :::6200  :::*  LISTEN  [PID]/java
```

### Application Deployment
```bash
# Check if WAR was extracted
ls -la /opt/tomcat/latest/webapps/

# Should see:
# ROOT.war (original)
# ROOT/ (extracted directory)
```

### Application Response
```bash
# Test from localhost
curl http://localhost:6200

# Test using hostname
curl http://stapp01:6200

# Check HTTP headers
curl -I http://stapp01:6200

# Expected: HTTP/1.1 200 OK
```

### View Logs
```bash
# Check Tomcat startup logs
tail -f /opt/tomcat/latest/logs/catalina.out

# Look for:
# "Deployment of web application archive [ROOT.war] has finished"
# "Server startup in [X] milliseconds"
```

## 🔒 Security Features

| Feature | Implementation |
|---------|----------------|
| **Non-root execution** | Dedicated `tomcat` user with limited shell |
| **Service isolation** | Systemd sandboxing and resource limits |
| **File permissions** | Proper ownership (tomcat:tomcat) |
| **Custom port** | Non-standard port 6200 (reduces automated attacks) |
| **Process monitoring** | Systemd automatic restart on failure |
| **Memory limits** | JVM heap size constraints (-Xms/-Xmx) |

## 📊 Technical Details

**Stack Components:**
- **OS**: CentOS/RHEL Linux
- **Runtime**: Java OpenJDK 1.8
- **Application Server**: Apache Tomcat 9.0.75
- **Service Manager**: systemd
- **Application**: Java WAR (Web Application Archive)

**Key Configurations:**
- **HTTP Port**: 6200
- **Shutdown Port**: 8005 (default)
- **AJP Port**: 8009 (default)
- **Heap Memory**: 512M initial, 1024M maximum
- **GC Algorithm**: Parallel GC

**File Locations:**
```
/opt/tomcat/latest/
├── bin/                 # Executables and scripts
├── conf/                # Configuration files
│   └── server.xml       # Main server configuration
├── logs/                # Application and access logs
├── temp/                # Temporary files
├── webapps/             # Deployed applications
│   ├── ROOT.war         # Original WAR file
│   └── ROOT/            # Extracted application
└── work/                # Compiled JSP files
```

## 🎓 Key Learnings

### Application Server Management
- **Symbolic links** simplify version management and upgrades
- **Systemd integration** provides robust process management
- **WAR auto-deployment** reduces manual deployment steps
- **Service users** enhance security through privilege separation

### Configuration Management
- **Environment variables** centralize configuration
- **Port customization** supports multiple instances or security requirements
- **Resource limits** prevent runaway processes
- **Auto-restart** improves availability

### Production Readiness
- **Logging** enables troubleshooting and monitoring
- **Health checks** via HTTP status codes
- **Service monitoring** with systemd status
- **Graceful shutdown** prevents data loss

## 🔄 Operational Tasks

### Restart Tomcat
```bash
systemctl restart tomcat
```

### View Real-time Logs
```bash
tail -f /opt/tomcat/latest/logs/catalina.out
```

### Deploy New Application
```bash
# Stop Tomcat
systemctl stop tomcat

# Replace WAR file
cp /path/to/new/ROOT.war /opt/tomcat/latest/webapps/
chown tomcat:tomcat /opt/tomcat/latest/webapps/ROOT.war

# Start Tomcat
systemctl start tomcat
```

### Check Application Files
```bash
# List deployed applications
ls -la /opt/tomcat/latest/webapps/

# View configuration
cat /opt/tomcat/latest/conf/server.xml
```

## 🚀 Potential Enhancements

### Performance Optimization
```bash
# Tune JVM parameters in tomcat.service
Environment="CATALINA_OPTS=-Xms2G -Xmx4G -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Security Hardening
- Enable HTTPS/TLS with SSL certificates
- Configure Tomcat manager application (admin interface)
- Implement request filtering and rate limiting
- Set up fail2ban for brute force protection
- Regular security updates and patching

### Monitoring & Alerting
- Integrate with Prometheus/Grafana for metrics
- Set up log aggregation (ELK stack)
- Configure health check endpoints
- Implement APM (Application Performance Monitoring)

### High Availability
- Load balancer in front of multiple Tomcat instances
- Session replication/clustering
- Database connection pooling optimization
- CDN for static content

## 📝 Troubleshooting

### Tomcat Won't Start
```bash
# Check logs for errors
tail -50 /opt/tomcat/latest/logs/catalina.out

# Verify Java is installed
java -version

# Check port conflicts
netstat -tulpn | grep 6200

# Verify permissions
ls -la /opt/tomcat/latest/bin/startup.sh
```

### Application Returns 404
```bash
# Check if WAR was deployed
ls -la /opt/tomcat/latest/webapps/

# If ROOT/ directory missing, wait for extraction
# Tomcat takes 10-20 seconds to extract WAR files

# Check deployment logs
grep -i "ROOT" /opt/tomcat/latest/logs/catalina.out
```

### Port Not Accessible
```bash
# Check firewall
firewall-cmd --list-ports
firewall-cmd --permanent --add-port=6200/tcp
firewall-cmd --reload

# Verify server.xml has correct port
grep 6200 /opt/tomcat/latest/conf/server.xml
```

### Service Fails to Start
```bash
# Check systemd logs
journalctl -u tomcat.service -n 50

# Verify service file syntax
systemd-analyze verify /etc/systemd/system/tomcat.service

# Reload daemon after changes
systemctl daemon-reload
```

## 📚 References

- [Apache Tomcat Documentation](https://tomcat.apache.org/tomcat-9.0-doc/)
- [Systemd Service Management](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [Java Performance Tuning](https://docs.oracle.com/javase/8/docs/technotes/guides/vm/gctuning/)
- [Tomcat Security Best Practices](https://tomcat.apache.org/tomcat-9.0-doc/security-howto.html)

## 📄 License

This project is open source and available under the MIT License.

---

Last Updated: October 2025  
Author: Junior Neba  
Contact: www.linkedin.com/in/junior-neba-20a385192  
