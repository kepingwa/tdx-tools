#!/bin/bash

set -e

CURR_DIR=$(dirname "$(readlink -f "$0")")

PACKAGES_GUEST=( \
    intel-mvp-tdx-guest-grub2 \
    intel-mvp-tdx-guest-kernel \
    intel-mvp-tdx-guest-shim \
    )

PACKAGES_HOST=( \
    intel-mvp-tdx-host-kernel \
    intel-mvp-tdx-libvirt \
    intel-mvp-tdx-qemu-kvm \
    intel-mvp-tdx-tdvf \
    )

build_repo() {
    packages=("${@:2}")
    repo_type=$1
    mkdir -p "${CURR_DIR}"/repo/"${repo_type}"/src

    for package in "${packages[@]}"; do
        pushd "${CURR_DIR}"/"${package}" || exit 1
        if [[ ! -f build.done ]]; then
            ./build.sh
            touch build.done
        fi
        if [[ ! -f rpm.done ]]; then
            cp ./rpmbuild/RPMS/* ../repo/"${repo_type}"/ -fr
            cp ./rpmbuild/SRPMS/* ../repo/"${repo_type}"/src -fr
            touch rpm.done
        fi
        popd || exit 1
    done

    pushd "${CURR_DIR}"/repo/"${repo_type}" || exit 1
    createrepo .
    popd || exit 1
}

# Check whether distro is "CentOS Stream 8"
[ -f /etc/centos-release ] || { echo "Invalid OS" && exit 1; }
[[ $(< /etc/centos-release) == "CentOS Stream release 8" ]] || \
    { echo "Invalid OS" && exit 1; }

# Check whether createrepo tool installed
if ! command -v "createrepo"
then
    echo "Did not find createrepo package, install..."
    dnf install createrepo -y
fi

# Build guest repo
build_repo "guest" "${PACKAGES_GUEST[@]}"

# Build host repo
build_repo "host" "${PACKAGES_HOST[@]}"
