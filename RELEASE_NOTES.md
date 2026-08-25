# Release Notes

## 1.5.0 — Token Monitor open-source candidate

- Adopted a source-only GitHub publication policy: no precompiled `.app`, DMG, PKG, or App ZIP is published.
- Added a multilingual disclosure that most code and parts of the technical documentation were generated or modified with OpenAI GPT/Codex assistance and then reviewed and tested by the maintainer.
- Renamed the product, App, executable, Swift modules, source archive, and release archive to the neutral `Token Monitor`／`TokenMonitor` identity.
- Added automatic migration from the legacy Keychain service name so existing saved API keys continue to work after the rename.
- Licensed source code and documentation under the MIT License.
- Explicitly excluded the character artwork and derived AppIcon from the MIT License; no separate artwork reuse license is granted.
- Added GitHub Actions macOS tests and package verification, issue and pull-request templates, a contribution guide, and a code of conduct.
- Kept the exact GPT image-generation product/model/date, applicable terms, and reference-input rights as source-publication review items. Bundle ID, Developer ID signing, and notarization apply only to a future binary release.

## 1.4.1 — Neutral mascot asset candidate

- Replaced the active mascot with the user-provided AI-generated `dragon-chibi-neutral-v4.png`.
- Removed the earlier OpenAI Blossom-like hair accessory from the character and regenerated the AppIcon from the neutral asset.
- Removed obsolete OpenAI-emblem wording from all three UI languages and documentation.
- Added an explicit AI-asset rights-status record; open-source asset licensing remains pending until generator terms and reference-input rights are documented.
- Kept the product-name, publisher identity, license, Developer ID, notarization, and support-channel release blockers explicit.

## 1.4.0 — Public release candidate

- Added an in-app disclaimer and privacy summary in Traditional Chinese, Simplified Chinese, and English.
- Added bundled disclaimer, privacy, security, third-party notice, and public-release checklist documents.
- Changed API networking to an ephemeral, no-cookie, no-disk-cache URLSession.
- Tightened Keychain accessibility so the saved credential is available only while the macOS user session is unlocked; credentials saved by older builds are migrated when first loaded.
- Removed unused mascot resources and extended metadata from the binary release package.
- Added a sanitized public source archive and repeatable release privacy checks.
- Removed private local paths from public documentation.
- Retained all desktop character, token display, localization, sound, icon, and window-size fixes from earlier versions.
