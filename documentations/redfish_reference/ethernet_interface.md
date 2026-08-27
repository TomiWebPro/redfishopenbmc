# EthernetInterface

A network interface (IPv4/IPv6, MAC, VLAN, DHCP) belonging to a Manager or System. Collected under {Manager,System}/EthernetInterfaces.

**Schema definition:** `EthernetInterface`  

**Example source (DMTF mockup):** `Managers/BMC/EthernetInterfaces/eth0/index.json`


## Example payload

```json
{
  "@odata.type": "#EthernetInterface.v1_12_0.EthernetInterface",
  "Id": "eth0",
  "Name": "Manager Ethernet Interface",
  "Description": "Management network interface on a dedicated port",
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "LinkStatus": "LinkUp",
  "InterfaceEnabled": true,
  "PermanentMACAddress": "23:11:8A:33:CF:EA",
  "MACAddress": "23:11:8A:33:CF:EA",
  "SpeedMbps": 100,
  "AutoNeg": true,
  "FullDuplex": true,
  "MTUSize": 1500,
  "HostName": "web483-bmc",
  "FQDN": "web483-bmc.dmtf.org",
  "MaxIPv6StaticAddresses": 1,
  "VLAN": {
    "VLANEnable": true,
    "VLANId": 101
  },
  "IPv4Addresses": [
    {
      "Address": "192.168.0.10",
      "SubnetMask": "255.255.252.0",
      "AddressOrigin": "DHCP",
      "Gateway": "192.168.0.1"
    }
  ],
  "IPv6AddressPolicyTable": [
    {
      "Prefix": "::1/128",
      "Precedence": 50,
      "Label": 0
    }
  ],
  "IPv6StaticAddresses": [
    {
      "Address": "fe80::1ec1:deff:fe6f:1e24",
      "PrefixLength": 16
    }
  ],
  "IPv6DefaultGateway": "fe80::1ec1:deff:fe6f:1e24",
  "IPv6Addresses": [
    {
      "Address": "fe80::1ec1:deff:fe6f:1e24",
      "PrefixLength": 64,
      "AddressOrigin": "SLAAC",
      "AddressState": "Preferred"
    }
  ],
  "NameServers": [
    "names.dmtf.org"
  ],
  "Links": {
    "Ports": [
      {
        "@odata.id": "/redfish/v1/Managers/BMC/DedicatedNetworkPorts/1"
      }
    ]
  },
  "@Redfish.Settings": {
    "@odata.type": "#Settings.v1_3_5.Settings",
    "SettingsObject": {
      "@odata.id": "/redfish/v1/Managers/BMC/EthernetInterfaces/eth0/SD"
    },
    "Time": "2012-03-07T14:44.30-05:00",
    "ETag": "84ffcbb050ddc7fa9cddb59014546e59",
    "Messages": [
      {
        "MessageId": "Base.1.0.SettingsFailed",
        "RelatedProperties": [
          "/IPv6Addresses/PrefixLength"
        ]
      }
    ]
  },
  "@odata.id": "/redfish/v1/Managers/BMC/EthernetInterfaces/eth0",
  "@Redfish.Copyright": "Copyright 2014-2023 DMTF. For the full DMTF copyright policy, see http://www.dmtf.org/about/policies/copyright."
}
```


## Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `@odata.context` | context | No | see mockup |
| `@odata.etag` | etag | No | see mockup |
| `@odata.id` | id | Yes | see mockup |
| `@odata.type` | type | Yes | see mockup |
| `Actions` | Actions | No | The available actions for this resource. |
| `AutoNeg` | boolean | No | An indication of whether the speed and duplex are automatically negotiated and configured on this interface. |
| `DHCPv4` | DHCPv4Configuration | No | DHCPv4 configuration for this interface. |
| `DHCPv6` | DHCPv6Configuration | No | DHCPv6 configuration for this interface. |
| `Description` | Description | No | see mockup |
| `EthernetInterfaceType` | EthernetDeviceType | No | The type of interface. |
| `FQDN` | string | No | The complete, fully qualified domain name that DNS obtains for this interface. |
| `FullDuplex` | boolean | No | An indication of whether full-duplex mode is enabled on the Ethernet connection for this interface. |
| `HostName` | string | No | The DNS host name, without any domain information. |
| `IPv4Addresses` | array of IPv4Address | No | The IPv4 addresses currently in use by this interface. |
| `IPv4StaticAddresses` | array of IPv4Address | No | The IPv4 static addresses assigned to this interface. See `IPv4Addresses` for the addresses in use by this interface. |
| `IPv6AddressPolicyTable` | array of IPv6AddressPolicyEntry | No | An array that represents the RFC6724-defined address selection policy table. |
| `IPv6Addresses` | array of IPv6Address | No | The IPv6 addresses currently in use by this interface. |
| `IPv6DefaultGateway` | string | No | The IPv6 default gateway address in use on this interface. |
| `IPv6Enabled` | boolean | No | An indication of whether IPv6 is enabled on this interface. |
| `IPv6StaticAddresses` | array of IPv6StaticAddress | No | The IPv6 static addresses assigned to this interface. See `IPv6Addresses` for the addresses in use by this interface. |
| `IPv6StaticDefaultGateways` | array of IPv6GatewayStaticAddress | No | The IPv6 static default gateways for this interface. |
| `Id` | Id | Yes | see mockup |
| `InterfaceEnabled` | boolean | No | An indication of whether this interface is enabled. |
| `LinkStatus` | LinkStatus | No | The link status of this interface, or port. |
| `Links` | Links | No | The links to other resources that are related to this resource. |
| `MACAddress` | MACAddress | No | The currently configured MAC address of the interface, or logical port. |
| `MTUSize` | integer | No | The currently configured maximum transmission unit (MTU), in bytes, on this interface. |
| `MaxIPv6StaticAddresses` | integer | No | The maximum number of static IPv6 addresses that can be configured on this interface. |
| `Name` | Name | Yes | see mockup |
| `NameServers` | array of string | No | The DNS servers in use on this interface. |
| `Oem` | Oem | No | The OEM extension property. |
| `PermanentMACAddress` | MACAddress | No | The permanent MAC address assigned to this interface, or port. |
| `RoutingScope` | RoutingScope | No | The routing scope for this interface. |
| `SpeedMbps` | integer | No | The current speed, in Mbit/s, of this interface. |
| `StatelessAddressAutoConfig` | StatelessAddressAutoConfiguration | No | Stateless address autoconfiguration (SLAAC) parameters for this interface. |
| `StaticNameServers` | array of string | No | The statically-defined set of DNS server IPv4 and IPv6 addresses. |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `TeamMode` | TeamMode | No | The team mode for this interface. |
| `UefiDevicePath` | string | No | The UEFI device path for this interface. |
| `VLAN` | VLAN | No | If this network interface supports more than one VLAN, this property is absent. VLAN collections appear in the `Links` property of this resource. |
| `VLANs` | VLanNetworkInterfaceCollection | No | The link to a collection of VLANs, which applies only if the interface supports more than one VLAN. If this property applies, the `VLANEnabled` and `VLANId` properties do not apply. |

