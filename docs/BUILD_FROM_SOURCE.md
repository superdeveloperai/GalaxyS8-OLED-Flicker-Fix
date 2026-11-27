# Building the Patched Kernel from Source

These steps reproduce `boot_patched_g950f_hadesKernel_v1.5_pie.img` using a native `arm64` Ubuntu 20.04 Docker container (or any native ARM64 Linux host).

> **macOS Note:** Do **not** build the Linux kernel directly on a case-insensitive APFS volume—files like `TlcTui.o` vs `tlcTui.o` and `net/netfilter/xt_*` will collide. Always build inside a case-sensitive Linux `ext4` Docker volume.

## 1. Build the Docker Image
```sh
docker build -t s8-kernel-builder-arm64 ./docker
```

## 2. Clone `hadesKernel` & Apply the Patch
```sh
git clone --depth 1 --branch 9 https://github.com/corsicanu/android_kernel_samsung_universal8895.git kernel_src
cd kernel_src
git apply ../patches/0001-panel_bl-clamp-min-hw-brightness.patch
```

## 3. Configure & Compile `Image`
Copy your device's `/proc/config.gz` (or use `exynos8895-dreamlte_defconfig`):
```sh
docker volume create s8-kbuild
docker run --rm -v "$(pwd):/work" -v "s8-kbuild:/build" s8-kernel-builder-arm64 bash -c '
  set -e
  cp -a /work/kernel_src /build/kernel_src
  cd /build/kernel_src
  make ARCH=arm64 CCACHE= exynos8895-dreamlte_defconfig
  make -j$(nproc) ARCH=arm64 CCACHE= Image
  cp arch/arm64/boot/Image /work/Image_patched
'
```

## 4. Repack with Your Existing Ramdisk (Preserves Magisk)
Unpack your backed-up `boot_backup.img` and swap in `Image_patched`:
```sh
docker run --rm -v "$(pwd):/work" s8-kernel-builder-arm64 bash -c '
  set -e
  mkdir -p /work/boot_unpack && cd /work/boot_unpack
  abootimg -x /work/boot_backup.img
  grep -v "^bootsize" bootimg.cfg > bootimg_new.cfg
  abootimg --create /work/boot_patched.img -f bootimg_new.cfg -k /work/Image_patched -r initrd.img
'
```
