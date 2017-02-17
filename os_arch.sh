#!/bin/sh

if [ -x /usr/bin/lsb_release ]; then
    DISTRIB=`lsb_release -si|tr '[:upper:]' '[:lower:]'`
    VERSION=`lsb_release -sr`
elif [ -e /etc/os-release ]; then
    DISTRIB=`cat /etc/os-release|grep '^ID='|cut -d '=' -f 2|sed s/\"//g|tr '[:upper:]' '[:lower:]'`
    VERSION=`cat /etc/os-release|grep '^VERSION='|cut -d '=' -f 2|cut -d ' ' -f 1|sed s/\"//g`
elif [ -e /etc/redhat-release ]; then
    DISTRIB="centos"
    VERSION=`cat /etc/redhat-release|sed s/\ /\\\\n/g|grep '\.'`
else
    DISTRIB=`uname -s|tr '[:upper:]' '[:lower:]'`
    VERSION=`uname -r`
fi
ARCH=`uname -m`

# Map binary compatible operating systems and versions onto one another
case $DISTRIB in
    "redhatenterpriseclient" | "redhatenterpriseserver" | "rhel" | "scientificsl" | "scientific" | "centos" | "scientificfermi" | "scientificcernslc")
        DISTRIB="RHEL"
        VERSION=`echo "${VERSION}" | cut -d '.' -f 1`
        ;;
    "ubuntu")
        DISTRIB="Ubuntu"
        if echo $VERSION | grep -q '16\.\?'; then
            VERSION="16.04"
        elif echo $VERSION | grep -q '15\.10'; then
            VERSION="15.10"
        elif echo $VERSION | grep -q '15\.\?'; then
            VERSION="14.04"
        elif echo $VERSION | grep -q '14\.\?'; then
            VERSION="14.04"
        elif echo $VERSION | grep -q '13\.\?'; then
            VERSION="12.04"
        elif echo $VERSION | grep -q '12\.\?'; then
            VERSION="12.04"
        fi
        ;;
    "debian")
        DISTRIB="Ubuntu"
        if [ "$VERSION" = "testing" ]; then
            VERSION="16.04"
        elif echo $VERSION | grep -q '9\.\?'; then
            VERSION="16.04"
        elif echo $VERSION | grep -q '8\.\?'; then
            VERSION="14.04"
        fi
        ;;
    "freebsd")
        DISTRIB="FreeBSD"
        VERSION=`uname -r | cut -d '.' -f 1`
        ARCH=`uname -p`
        ;;
    "darwin")
        DISTRIB="OSX"
        VERSION=`uname -r | cut -d '.' -f 1`
        ;;
    "linux")
        # Damn. Try harder with the heuristics.
        if echo $VERSION | grep -q '\.el7\.\?'; then
            DISTRIB="RHEL"
            VERSION=7
        elif echo $VERSION | grep -q '\.el6\.\?'; then
            DISTRIB="RHEL"
            VERSION=6
        elif echo $VERSION | grep -q '\.el5\.\?'; then
            DISTRIB="RHEL"
            VERSION=5
        fi
esac

OS_ARCH=${DISTRIB}_${VERSION}_${ARCH}
export OS_ARCH
