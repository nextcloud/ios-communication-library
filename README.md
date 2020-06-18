# iOS communication library [beta]

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

To integrate **Nextcloud iOS Communication** into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "nextcloud/ios-communication-library" "master"
```

Run `carthage update` to build the framework and drag the built `NCCommunication.framework` into your Xcode project.

### Manual

To add **Nextcloud iOS Communication** to your app without Carthage, clone this repo and place it somewhere in your project folder. 
Then, add `NCCommunication.xcodeproj` to your project, select your app target and add the NCCommunication framework as an embedded binary under `General` and as a target dependency under `Build Phases`.

## Contribution Guidelines & License

[GPLv3](LICENSE.txt) with [Apple app store exception](COPYING.iOS).

Nextcloud doesn't require a CLA (Contributor License Agreement). The copyright belongs to all the individual contributors. Therefore we recommend that every contributor adds following line to the header of a file, if they changed it substantially:

```
@copyright Copyright (c) <year>, <your name> (<your email address>)
```

Please read the [Code of Conduct](https://nextcloud.com/code-of-conduct/). This document offers some guidance to ensure Nextcloud participants can cooperate effectively in a positive and inspiring atmosphere, and to explain how together we can strengthen and support each other.

More information how to contribute: [https://nextcloud.com/contribute/](https://nextcloud.com/contribute/)
