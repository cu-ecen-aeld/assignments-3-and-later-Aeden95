!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

CURRENT_DIR=$(pwd)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
    # wget https://github.com/bwalle/ptxdist-vetero/blob/f1332461242e3245a47b4685bc02153160c0a1dd/patches/linux-5.0/dtc-multiple-definition.patch
    # git apply dtc-multiple-definition.patch
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j8 mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j8 defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j8 all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j8 dtbs
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

cd $OUTDIR
mkdir rootfs
cd rootfs
mkdir -p lib lib64 proc sbin sys tmp usr var bin dev etc home
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    git switch -c ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# busy box 
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd ${ROOTFS}

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
SOURCEDIR=$(which ${CROSS_COMPILE}gcc)
SOURCEDIR=$(dirname ${SOURCEDIR})

# @TODO: Copy the dependencies
# 
cd "${SOURCEDIR}/.."
cp $(find . -name ld-linux-aarch64.so.1) ${OUTDIR}/rootfs/lib/
cp $(find . -name libm.so.6) ${OUTDIR}/rootfs/lib64/
cp $(find . -name libresolv.so.2) ${OUTDIR}/rootfs/lib64/
cp $(find . -name libc.so.6) ${OUTDIR}/rootfs/lib64/

# Make device nodes
cd "$ROOTFS"
sudo mknod dev/null c 1 3
sudo mknod dev/console c 5 1


# Clean and build the writer utility
cd "$FINDER_APP_DIR"
make CROSS_COMPILE="${CROSS_COMPILE}" clean
make CROSS_COMPILE="${CROSS_COMPILE}" writer
# Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp finder-test.sh finder.sh writer.sh writer ${OUTDIR}/rootfs/home
cp -r ../conf ${OUTDIR}/rootfs
cp -r conf ${OUTDIR}/rootfs/home

cp autorun-qemu.sh ${OUTDIR}/rootfs/home
# Chown the root directory

sudo chown -R root:root ${ROOTFS}

# Create initramfs.cpio.gz
cd ${ROOTFS}
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd $OUTDIR
gzip -f initramfs.cpio
