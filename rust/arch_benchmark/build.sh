RUSTFLAGS="-C target-feature=+crt-static" cross build --target armv7-unknown-linux-gnueabihf --release
RUSTFLAGS="-C target-feature=+crt-static" cross build --target x86_64-unknown-linux-gnu --release
RUSTFLAGS="-C target-feature=+crt-static" cross build --target powerpc-unknown-linux-gnu --release

echo 'Run with these commands:'
echo 'qemu-x86_64 target/x86_64-unknown-linux-gnu/release/arch_benchmark'
echo 'qemu-arm target/armv7-unknown-linux-gnueabihf/release/arch_benchmark'
echo 'qemu-ppc target/powerpc-unknown-linux-gnu/release/arch_benchmark'
