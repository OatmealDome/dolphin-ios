# StikJIT XCFramework

`StikJIT.xcframework` comes from the StikJIT 1.5.0 release. The original archive SHA-256 is `444b8d439df8455c34afbb51e279fd225265279195475f9b3fdbcf3a71a27e85`.

The release archive omitted its framework `Info.plist` and emitted module-qualified declarations that newer Swift compilers resolve against the public `StikJIT` enum instead of the module. This copy adds the missing bundle metadata and uses unqualified declarations in the public and private Swift interfaces. The compiled framework binary is unchanged.
