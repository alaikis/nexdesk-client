# Windows Code Signing Configuration

NEX uses Windows Authenticode code signing for release builds. This document describes how to configure signing for CI/CD.

## Prerequisites

1. **Code Signing Certificate**: Obtain an EV or Standard code signing certificate from a trusted CA (e.g., DigiCert, Sectigo, GlobalSign).
2. **PFX/P12 File**: Export your certificate as a PFX file with a strong password.
3. **Timestamp Server**: Use a timestamp server (e.g., `http://timestamp.digicert.com`) to ensure signatures remain valid after certificate expiration.

## GitHub Secrets

Store the following secrets in your GitHub repository settings (Settings > Secrets and variables > Actions):

| Secret | Description |
|--------|-------------|
| `WINDOWS_CERT_PFX` | Base64-encoded PFX certificate file |
| `WINDOWS_CERT_PASSWORD` | Password for the PFX file |

## CI Configuration

The signing step in `.github/workflows/build.yml` is currently a placeholder. To enable signing:

1. Uncomment the signing commands in the `Sign Windows binaries` step.
2. Ensure the `WINDOWS_CERT_PFX` and `WINDOWS_CERT_PASSWORD` secrets are set.
3. The signing will only run on tagged releases (`refs/tags/v*`).

## Local Signing

To sign binaries locally:

```powershell
# Convert PFX to P12 if needed
$p12 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$p12.Import("cert.pfx", "password", [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Sign the installer
signtool sign /f cert.pfx /p password /tr http://timestamp.digicert.com /td sha256 /fd sha256 NEX-Setup-*.exe

# Verify signature
signtool verify /pa NEX-Setup-*.exe
```

## Notes

- Signing is only performed on release builds (tagged commits).
- Development builds are unsigned.
- The timestamp ensures the signature remains valid even after the certificate expires.
