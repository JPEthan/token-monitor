# Security Policy

## Credential safety

- Never paste an OpenAI Admin API Key into a GitHub issue, discussion, screenshot, crash report, chat, or log.
- Revoke and rotate any key that may have been exposed.
- Use this app only if you trust the binary publisher or have built and reviewed the source yourself.
- Prefer a purpose-specific, revocable credential and review organization audit information regularly.

## Reporting a vulnerability

After this project is hosted, enable the repository's private vulnerability-reporting or security-advisory feature and publish a security contact. Do not report vulnerabilities that contain credentials through a public issue.

Until a private reporting channel is configured, this package must not claim to provide a supported security-response process. The publisher should add a monitored contact before a general-audience release.

## Supported builds

Only the newest published release should receive security fixes. Locally ad-hoc-signed candidates are not notarized by Apple and should be treated as development distributions unless the publisher signs and notarizes them with a Developer ID.

## Build integrity

Each release includes SHA-256 hashes. Verify downloaded files against hashes published through an independent trusted channel. A hash shipped only beside the same download protects against accidental corruption, not a compromised distributor.
