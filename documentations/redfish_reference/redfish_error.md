# RedfishError

The standard Redfish error response body returned on any non-2xx HTTP status. There is no standalone DMTF JSON schema for this shape (it is defined by the Redfish specification, not a resource schema), so the table below is derived from the specification.

## Example payload

```json
{
  "error": {
    "@Message.ExtendedInfo": [
      {
        "MessageId": "Base.1.0.GeneralError",
        "Message": "An error has occurred. See ExtendedInfo for more information.",
        "Severity": "Critical",
        "Resolution": "None"
      }
    ],
    "code": "Base.1.0.GeneralError",
    "message": "An error has occurred. See ExtendedInfo for more information."
  }
}
```


## Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `error` | object | Yes | The top-level error container. |
| `error.code` | string | Yes | A Redfish Message registry code (e.g. `Base.1.0.GeneralError`). |
| `error.message` | string | Yes | Human-readable summary message. |
| `error.@Message.ExtendedInfo` | array of object | No | Detailed message array; each item has `MessageId`, `Message`, `Severity`, `Resolution`, and optional `RelatedProperties`. |
