# Accord
A faster, native discord client for your Mac. Here's a [screenshot](https://github.com/evelyneee/accord#screenshot).

### OS Requirement

Accord requires macOS Big Sur (11.0) or higher

### Installing

#### Homebrew [Recommended]
[If you have Homebrew installed on your Mac](https://brew.sh), you can get the latest Accord release by installing the `accord` cask:
```
$ brew install --cask accord
```
To upgrade Accord using Homebrew, run the following:
```
$ brew upgrade --cask accord
```

#### GitHub Releases [Recommended]
Alternatively, you can [download the latest version of Accord via GitHub releases](https://github.com/evelyneee/accord/releases/latest). These builds will not receive automatic updates, so you will have to manually check for updates to benefit from the latest features and bug fixes.

#### TestFlight
[Install Accord via TestFlight](https://itunes.apple.com/us/app/testflight/id899247664?mt=8). This allows you to receive automatic updates, give feedback to the project, and stay up-to-date with changelogs. However, the TestFlight might be less updated.

### Building
Xcode 14.1 or above is required.
1. Download the project and open it in Xcode.
2. In the project settings, select the `Signing & Capabilities tab`, select your development team and input a new bundle ID.
3. Open your terminal app and `cd` into the directory. 
4. Run `xcodebuild`.

The built product will be in the `build/Release` directory

### Licensing
This project is licensed under the BSD 4-clause license.

### Support
* If you have questions, feel free to [ask them in our Discord server](https://discord.gg/nUGnmA9yFH)!
* If you'd like to report an issue, [please do so here](https://github.com/evelyneee/accord/issues/new).

## Screenshot

<img width="1196" alt="Screen Shot 2022-08-15 at 8 44 04 PM" src="https://user-images.githubusercontent.com/70823629/184759736-cef96abb-1b8d-4d69-97d9-e3b32ca8df67.png">
