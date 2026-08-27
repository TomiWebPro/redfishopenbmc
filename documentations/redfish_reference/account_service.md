# AccountService

Manages user accounts, roles, and account provider settings. Top resource under /redfish/v1/AccountService.

**Schema definition:** `AccountService`  

**Example source (DMTF mockup):** `AccountService/index.json`


## Example payload

```json
{
  "@odata.type": "#AccountService.v1_15_0.AccountService",
  "Id": "AccountService",
  "Name": "Account Service",
  "Description": "Account Service",
  "Status": {
    "State": "Enabled",
    "Health": "OK"
  },
  "ServiceEnabled": true,
  "AuthFailureLoggingThreshold": 3,
  "MinPasswordLength": 8,
  "AccountLockoutThreshold": 5,
  "AccountLockoutDuration": 30,
  "AccountLockoutCounterResetAfter": 30,
  "AccountLockoutCounterResetEnabled": true,
  "Accounts": {
    "@odata.id": "/redfish/v1/AccountService/Accounts"
  },
  "Roles": {
    "@odata.id": "/redfish/v1/AccountService/Roles"
  },
  "LocalAccountAuth": "Enabled",
  "MultiFactorAuth": {
    "OneTimePasscode": {
      "Enabled": true
    }
  },
  "LDAP": {
    "AccountProviderType": "LDAPService",
    "ServiceEnabled": false,
    "ServiceAddresses": [
      "ldaps://ldap.example.org:636"
    ],
    "Authentication": {
      "AuthenticationType": "UsernameAndPassword",
      "Username": "cn=Manager,dc=example,dc=org",
      "Password": null
    },
    "LDAPService": {
      "SearchSettings": {
        "BaseDistinguishedNames": [
          "dc=example,dc=org"
        ],
        "UsernameAttribute": "uid",
        "GroupsAttribute": "memberof",
        "EmailAttribute": "mail"
      }
    },
    "RemoteRoleMapping": [
      {
        "RemoteUser": "cn=Manager,dc=example,dc=org",
        "LocalRole": "Administrator"
      },
      {
        "RemoteGroup": "cn=Admins,ou=Groups,dc=example,dc=org",
        "LocalRole": "Administrator"
      }
    ]
  },
  "ActiveDirectory": {
    "AccountProviderType": "ActiveDirectoryService",
    "ServiceEnabled": true,
    "ServiceAddresses": [
      "ad1.example.org",
      "ad2.example.org"
    ],
    "Authentication": {
      "AuthenticationType": "KerberosKeytab",
      "KerberosKeytab": null
    },
    "RemoteRoleMapping": [
      {
        "RemoteGroup": "Administrators",
        "LocalRole": "Administrator"
      },
      {
        "RemoteUser": "DOMAIN\\Bob",
        "LocalRole": "Operator"
      }
    ]
  },
  "OAuth2": {
    "AccountProviderType": "OAuth2",
    "ServiceEnabled": true,
    "ServiceAddresses": [
      "https://contoso.org/.well-known/oauth-authorization-server"
    ],
    "OAuth2Service": {
      "Mode": "Discovery",
      "Issuer": "https://contoso.org/services/oauth2",
      "Audience": [
        "23:11:8A:33:CF:EA",
        "92384634-2938-2342-8820-489239905423"
      ],
      "OAuthServiceSigningKeys": "ewogICAgImtleXMiOiBbCiAgICAgICAgewogICAgICAgICAgICAiZSI6ICJBUUFCIiwKICAgICAgICAgICAgImtpZCI6ICJvV1F2Tl8tRUxnd25HMzFNTEl4Rm5hTVlfNTd0Wk9FSUVQYnpaYlBqS2FBIiwKICAgICAgICAgICAgImt0eSI6ICJSU0EiLAogICAgICAgICAgICAibiI6ICJvYS1Kb2pkSGw2VHQ3N2Vma2h6aW5MMU9XNmZjMGhjQjloOTN2WUZyRVlPakozRjhfTFh1c1ItMW95MUFKdExZcF9KeVI4Q1ZET28yVGNCaTBuSkhKczF1dkN4WWljX202WE5vMHptVm1VQ2hVMnBYSlBGelZKRGV5VVhIWWVONG5yQ1k4XzlTLXlzWnlKa2RRaWJmeHlBRndUMHdpNlZldF9MYTE4N3JNZUFCU0tXdEdIVmpkOWk1UmhELWNGU1JaNk05M0s2bXFPUUpaX0pMXzJKUU93aGk5dFl4Q2drVVpqc1gyWXowMEZpdUVTWDhHcXRGQlI1UzhIT2p0b2FhZUJrTk5hYWZFOFdSUVl6QlVmOHpiNkVobUFMemc0Z0YxTVhRb3dZV25GcGpzYXcwNVRONHk3SWZJUVhLODlqbGxnbWFkWVVjbndaUmRMc1o2VTdBS1EiCiAgICAgICAgfQogICAgXQp9"
    }
  },
  "AdditionalExternalAccountProviders": {
    "@odata.id": "/redfish/v1/AccountService/ExternalAccountProviders"
  },
  "OutboundConnections": {
    "@odata.id": "/redfish/v1/AccountService/OutboundConnections"
  },
  "RequireChangePasswordAction": false,
  "@odata.id": "/redfish/v1/AccountService",
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
| `AccountLockoutCounterResetAfter` | integer | No | The period of time, in seconds, between the last failed login attempt and the reset of the lockout threshold counter. This value must be less than or equal to the `AccountLockoutDuration` value. A reset sets the count... |
| `AccountLockoutCounterResetEnabled` | boolean | No | An indication of whether the threshold counter is reset after `AccountLockoutCounterResetAfter` expires. If `true`, it is reset. If `false`, only a successful login resets the threshold counter and if the user reaches... |
| `AccountLockoutDuration` | integer | No | The period of time, in seconds, that an account is locked after the number of failed login attempts reaches the account lockout threshold, within the period between the last failed login attempt and the reset of the l... |
| `AccountLockoutThreshold` | integer | No | The number of allowed failed login attempts before a user account is locked for a specified duration. If `0`, the account is never locked. |
| `Accounts` | ManagerAccountCollection | No | The collection of manager accounts. |
| `Actions` | Actions | No | The available actions for this resource. |
| `ActiveDirectory` | ExternalAccountProvider | No | The first Active Directory external account provider that this account service supports. |
| `AdditionalExternalAccountProviders` | ExternalAccountProviderCollection | No | The additional external account providers that this account service uses. |
| `AuthFailureLoggingThreshold` | integer | No | The number of authorization failures per account that are allowed before the failed attempt is logged to the manager log. |
| `Description` | Description | No | see mockup |
| `EnforcePasswordHistoryCount` | integer | No | The number of unique new passwords that need to be associated with a user account before a previous password is accepted when modifying the password. If `0`, a user does not need to provide a unique new password. |
| `HTTPBasicAuth` | BasicAuthState | No | Indicates if HTTP Basic authentication is enabled for this service. |
| `Id` | Id | Yes | see mockup |
| `LDAP` | ExternalAccountProvider | No | The first LDAP external account provider that this account service supports. |
| `LocalAccountAuth` | LocalAccountAuth | No | An indication of how the service uses the accounts collection within this account service as part of authentication. The enumerated values describe the details for each mode. |
| `MaxPasswordLength` | integer | No | The maximum password length for this account service. |
| `MinPasswordLength` | integer | No | The minimum password length for this account service. |
| `MultiFactorAuth` | MultiFactorAuth | No | The multi-factor authentication settings that this account service supports. |
| `Name` | Name | Yes | see mockup |
| `OAuth2` | ExternalAccountProvider | No | The first OAuth 2.0 external account provider that this account service supports. |
| `Oem` | Oem | No | The OEM extension property. |
| `OutboundConnections` | OutboundConnectionCollection | No | The collection of outbound connection configurations. |
| `PasswordExpirationDays` | integer | No | The number of days before account passwords in this account service will expire. |
| `PasswordGuidanceMessage` | string | No | Password creation guidance for manager accounts. |
| `PasswordGuidanceMessageId` | string | No | A `MessageId` that contains password creation guidance for manager accounts. |
| `PrivilegeMap` | PrivilegeRegistry | No | The link to the mapping of the privileges required to complete a requested operation on a URI associated with this service. |
| `RequireChangePasswordAction` | boolean | No | An indication of whether clients are required to invoke the `ChangePassword` action to modify account passwords. |
| `RestrictedOemPrivileges` | array of string | No | The set of restricted OEM privileges. |
| `RestrictedPrivileges` | array of PrivilegeType | No | The set of restricted Redfish privileges. |
| `Roles` | RoleCollection | No | The collection of Redfish roles. |
| `ServiceEnabled` | boolean | No | An indication of whether the account service is enabled. If `true`, it is enabled. If `false`, it is disabled and users cannot be created, deleted, or modified, and new sessions cannot be started. However, established... |
| `Status` | Status | No | The status and health of the resource and its subordinate or dependent resources. |
| `SupportedAccountTypes` | array of AccountTypes | No | The account types supported by the service. |
| `SupportedOEMAccountTypes` | array of string | No | The OEM account types supported by the service. |
| `TACACSplus` | ExternalAccountProvider | No | The first TACACS+ external account provider that this account service supports. |

