# Third-Party Notices and Asset Status

## OpenAI

This independent app interoperates with the OpenAI API. OpenAI, ChatGPT, API names, and related marks are property of their respective owners. The app is not sponsored, endorsed, approved by, affiliated with, or partnered with OpenAI.

No OpenAI SDK is bundled. The app sends HTTPS requests directly to the documented Organization Usage endpoint.

Most source code, initial implementations, refactoring suggestions, and portions of the technical documentation were generated or modified with assistance from OpenAI GPT/Codex. The project maintainer reviewed, modified, tested, and selected the published result. This assistance does not make the project an official OpenAI product or imply OpenAI review, approval, endorsement, or support. See [AI_DISCLOSURE.md](AI_DISCLOSURE.md).

## Character artwork and app icon

The white-and-purple chibi dragon character was supplied by the project owner, who states that it was created with OpenAI GPT image generation. Version 1.5.0 uses `dragon-chibi-neutral-v4.png`, which removes the earlier OpenAI Blossom-like hair accessory. The AppIcon is generated from this same neutral asset.

The repository's MIT License applies to source code and documentation, but expressly excludes the character and AppIcon. No separate right to reuse, modify, sublicense, or redistribute those artwork files is granted. Removing the visible mark resolves that specific artwork-brand issue, but it does not by itself establish copyright ownership or redistribution rights. The exact generating product/model/date, applicable terms, and rights in every reference input still require confirmation. See [ASSET_RIGHTS.md](ASSET_RIGHTS.md) and [ASSET_LICENSE.md](ASSET_LICENSE.md). Attribution or a disclaimer alone does not create permission.

## Apple frameworks

The app links only Apple system frameworks (AppKit, AVFoundation, Security, and SwiftUI) and the Swift standard libraries supplied by the platform toolchain.

## Source-code dependencies

The Swift package currently has no third-party package dependencies.

The desktop-character interaction was independently implemented in Swift after reviewing the user-supplied DSH whale-widget demonstration. No JavaScript package from that project is bundled in this Swift package. Before publication, the publisher should still retain a short provenance record and confirm that no copied third-party code or assets require an additional notice.
