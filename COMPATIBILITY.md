# Compatibility

[Simplified Chinese](COMPATIBILITY.zh-CN.md)

ppos 0.2.0 targets QEMU's x86-64 `pc` machine with Multiboot v1, an emulated
PS/2 keyboard, ATA disk, and Intel e1000 network device. The published image is
not a general PC hardware compatibility claim.

The build requires pplang, pplc, and pptc 0.4.0. Component source commits and
checksums are locked in `pp.lock`. POSIX compatibility is not provided.

The release locks ossh 0.1.1, ppnet 0.2.0, oscore 0.1.3, and osbare 0.1.1.
Networking assumes QEMU user networking at `10.0.2.0/24`; DHCP, IPv6, and a
system CA store are not provided.
