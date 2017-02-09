#!/bin/sh

if [ -x /usr/bin/lsb_release ]; then
    DISTRIB=`lsb_release -si`
    VERSION=`lsb_release -sr`
else
    DISTRIB=`uname -s`
    VERSION=`uname -r`
fi
ARCH=`uname -m`

# Map binary compatible operating systems and versions onto one another
case $DISTRIB in
    "RedHatEnterpriseClient" | "RedHatEnterpriseServer" | "ScientificSL" | "Scientific" | "CentOS" | "ScientificFermi" | "ScientificCERNSLC")
        DISTRIB="RHEL"
        VERSION=`lsb_release -sr | cut -d '.' -f 1`
        ;;
    "Ubuntu")
        VERSION=`lsb_release -sr | cut -d '.' -f 1,2`
        case $VERSION in
            "15.04" | "14.10")
                VERSION="14.04"
                ;;
            "13.10" | "13.04" | "12.10")
                VERSION="12.04"
                ;;
        esac
        ;;
    "Debian")
        DISTRIB="Ubuntu"
        if [ "$VERSION" = "testing" ]; then
            VERSION="16.04"
        elif echo $VERSION | grep -q '9\.\?'; then
            VERSION="16.04"
        elif echo $VERSION | grep -q '8\.\?'; then
            VERSION="14.04"
        elif echo $VERSION | grep -q '7\.\?'; then
            VERSION="11.04"
        elif echo $VERSION | grep -q '6\.\?'; then
            VERSION="10.04"
        fi
        ;;
    "FreeBSD")
        VERSION=`uname -r | cut -d '.' -f 1`
        ARCH=`uname -p`
        ;;
    "Darwin")
        VERSION=`uname -r | cut -d '.' -f 1`
        ;;
    "Linux")
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
