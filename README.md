# This is no longer supported, please consider using [NextcloudKit](https://github.com/nextcloud/NextcloudKit) instead.

# iOS communication library 

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
