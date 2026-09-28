# StikJIT XCFramework

`StikJIT.xcframework` comes from the StikJIT 1.9.0 release. The original archive SHA-256 is `806664393770c68e75f2b6429955bfdd88cfaad09fec2ba70f8ed615ff90c060`.

The release archive omitted its framework `Info.plist` and emitted module-qualified declarations that the project's Swift compiler resolves against the public `StikJIT` enum instead of the module. This copy adds the missing bundle metadata and uses compatible declarations in the public and private Swift interfaces. The compiled framework binary is unchanged.
