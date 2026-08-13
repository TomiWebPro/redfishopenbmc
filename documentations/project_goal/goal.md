# Redfish Multi-System Control App (Flutter) - End Goal Specification

## Overview

This project aims to build a **modern, elegant, cross-platform Flutter application** that provides a unified interface for managing servers via the **Redfish API** exposed by Baseboard Management Controllers (BMCs), including OpenBMC-based systems.

The application will allow users to:

- Connect to one or multiple servers using IP + port
- Authenticate securely with Redfish endpoints
- Dynamically discover available Redfish capabilities per system
- Render only supported features (no static UI assumptions)
- Control power, monitor hardware, access remote KVM, and perform firmware/system management tasks
- Scale seamlessly across mobile, desktop, and web platforms

The design philosophy is:

> **"Everything is discovered, nothing is assumed."**

---

## Core Goals

### 1. Multi-System Management

The application must support:

- Adding multiple BMC targets
- Storing connection profiles (IP, port, credentials, auth method)
- Switching between systems instantly
- Viewing system status in a unified dashboard

Each system is treated as an independent Redfish-capable node.

---

### 2. Dynamic Feature Discovery (Schema-Driven UI)

The app must NOT assume available features.

Instead, it must:

- Query `/redfish/v1/` root endpoint
- Traverse resource trees:
  - `/Systems`
  - `/Managers`
  - `/Chassis`
  - `/UpdateService`
  - `/SessionService`
- Inspect Redfish schemas and OData metadata
- Detect supported actions dynamically (e.g. `Reset`, `IndicatorLed`, `VirtualMedia`)
- Render UI components ONLY when features exist

If a feature is unavailable:
- It must NOT be displayed
- No placeholder or disabled UI unless explicitly required for UX clarity

---

### 3. Core Functional Capabilities

#### 3.1 Power Management

- Power ON
- Power OFF
- Graceful restart
- Forced reset
- Power state visualization

Mapped to:
`/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset`

---

#### 3.2 System Overview Dashboard

Each system must display:

- Power state
- Health status (OK / Warning / Critical)
- Manufacturer / model
- CPU / memory summary (if available)
- Temperature sensors (if exposed)

---

#### 3.3 Remote KVM (if available)

If supported by Redfish/OEM extensions:

- Launch HTML5 or embedded KVM session
- Fullscreen remote console mode
- Keyboard / mouse input forwarding
- Session persistence handling

---

#### 3.4 Sensor Monitoring

- Real-time temperature graphs
- Fan speeds
- Voltage readings
- Alerts and thresholds

Only render sensors present in Redfish schema.

---

#### 3.5 Firmware & Update Management

If supported:

- Upload firmware images
- Monitor update progress
- Trigger update jobs
- Display update logs

---

#### 3.6 Account & Session Management

- Login via:
  - Basic Auth
  - Redfish session tokens
- Session refresh handling
- Secure credential storage (platform keystore)

---

## UI/UX Design Principles

### 1. Modern Minimal Interface

- Clean dashboard per system
- Card-based layout for systems
- Smooth transitions and animations
- Dark mode first-class support
- Adaptive layout (mobile → desktop scaling)

---

### 2. Responsive Cross-Platform Design

Must support:

- Mobile (iOS / Android)
- Desktop (Windows / macOS / Linux)
- Web browser

Layout behavior:

- Mobile → vertical stacked cards
- Tablet → split panels
- Desktop → multi-pane management console

---

### 3. System-Centric Navigation Model

Each system has:

- Overview tab
- Power controls tab
- Sensors tab
- Firmware tab (if available)
- KVM tab (if available)
- Advanced raw Redfish explorer (optional developer mode)

---

### 4. Real-Time Feedback

- Live status polling or WebSocket (if supported)
- Animated state transitions (power changes, sensor updates)
- Non-blocking UI updates

---

## Architecture Overview

### High-Level Structure

```text
Flutter UI Layer
    |
    |-- System Manager (multi-host orchestration)
    |
    |-- Redfish Client Layer
    |       - HTTP/HTTPS handling
    |       - Auth/session manager
    |       - schema parser
    |
    |-- Feature Discovery Engine
    |       - endpoint traversal
    |       - capability detection
    |
    |-- State Management (e.g. Riverpod / Bloc)
    |
    |-- Local Secure Storage
```

---

# Key Design Rule

UI is always a reflection of the Redfish schema, never hardcoded.

Redfish Integration Strategy

The system must:

Start at /redfish/v1/
Discover entry points
Traverse linked resources (@odata.id)
Cache schema results per system
Detect:
Actions
Properties
Optional OEM extensions
Normalize into internal feature model:
{
  "system_id": "bmc1",
  "features": {
    "power_control": true,
    "kvm": false,
    "firmware_update": true,
    "sensor_monitoring": true
  }
}
Multi-System Support Model

Each system instance contains:

Connection profile
Auth session
Cached schema tree
Feature availability map
Live state snapshot

Users can:

Compare systems
Switch context instantly
View aggregated status dashboard
Security Requirements
TLS-first communication (HTTPS only where possible)
Credential encryption at rest
Session token isolation per system
No persistent plaintext passwords
Optional integration with OS keychain / secure enclave
Performance Requirements
Lazy-load Redfish endpoints
Cache schema discovery results
Minimize API calls via delta polling
Support low-bandwidth environments (datacenter remote access scenarios)
Developer/Agent Instructions

This project is schema-driven and evolving.

The development agent must:
Continuously study:
Redfish specification (DMTF standard)
OpenBMC Redfish implementation
Vendor-specific OEM extensions

Maintain and update this document:
Add newly discovered Redfish capabilities
Expand feature mapping logic
Update UI rendering rules as schema evolves
Treat this document as a living architecture contract
After each implementation milestone:
Revisit assumptions
Update feature discovery model
Refine UI abstraction layers
Long-Term Vision

This application should evolve into:

A universal, vendor-agnostic, visually modern control plane for all Redfish-enabled infrastructure.

It should eventually support:

Datacenter-scale fleet management
Role-based access control (RBAC)
Automation hooks (Terraform / Ansible integration)
Plugin system for OEM-specific extensions
Summary

This is not just a UI app.

It is a dynamic control interface for infrastructure itself, where:

Redfish is the source of truth
UI is generated from capability discovery
Every system is self-describing
Nothing is assumed, everything is queried