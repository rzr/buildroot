#!/bin/bash

set -x
set -e

usage_()
{
    cat<<EOF
# URL: https://github.com/tizenteam/buildroot/tree/avatar
# docker run ubuntu:12.04 cat /etc/issue
# docker run -ti ubuntu:12.04 
EOF
}


setup_()
{
    cd $HOME
    apt-get update ; apt-get install git ;
    git config --global user.name "Git user"
    git config --global user.email "root@localhost.localdomain"
    apt-get install etckeeper ; #TODO use git
    cd /etc
    git commit --amend --reset-author

    apt-get install \
        screen sudo unp curl wget zile locales openssh-server

    bash
    screen

    apt-get install \
        make rsync bzip2 unzip whois bc \
        ia32-libs-multiarch libncurses-dev\
 build-essential \
        g++ php5 \
        #eol

    sed -b -e 's|^define|%define|g' -i /usr/share/i18n/locales/* # or just tr_TR
}


dl_crawl_()
{
    for i in $(seq 1 9); do
        for j in $(seq 1 9); do
            wget -c http://download.wdc.com/nas/MyPassportWireless_1.0$i.0$j.bin
            wget -c http://download.wdc.com/nas/MyPassportWireless_1.0$i.1$j.bin
            wget -c http://download.wdc.com/nas/MyPassportWireless_1.1$i.0$j.bin
            wget -c http://download.wdc.com/nas/MyPassportWireless_1.0$i.1$j.bin
        done
    done


    ll='
https://buildroot.org/downloads/buildroot-2016.11.2.tar.gz
'
}


import_()
{
    l='
http://downloads.wdc.com/gpl/buildroot-GPL_1_01_09.tgz
http://downloads.wdc.com/gpl/buildroot-GPL_1_02_15.tgz
http://downloads.wdc.com/gpl/buildroot-GPL_1_02_17.tgz
http://downloads.wdc.com/gpl/buildroot-GPL_1_03_13.tgz
http://downloads.wdc.com/gpl/GPL-v1_04_06-20150605.zip
http://downloads.wdc.com/gpl/buildroot-GPL-FW1_05_01.tgz
http://downloads.wdc.com/gpl/buildroot-GPL-FW1_07_02.tgz
'

    ll='
http://download.wdc.com/nas/MyPassportWireless_1.01.01.bin
http://download.wdc.com/nas/MyPassportWireless_1.01.06.bin
http://download.wdc.com/nas/MyPassportWireless_1.01.09.bin
http://download.wdc.com/nas/MyPassportWireless_1.07.02.bin
'
    llf='
MyPassportWireless_1.01.01.bin
MyPassportWireless_1.01.06.bin

MyPassportWireless_1.01.09.bin

MyPassportWireless_1.02.15.bin

MyPassportWireless_1.02.17.bin

MyPassportWireless_1.03.13.bin

MyPassportWireless_1.04.05.bin

MyPassportWireless_1.04.06.bin

MyPassportWireless_1.05.01.bin
MyPassportWireless_1.06.05.bin
MyPassportWireless_1.06.06.bin
MyPassportWireless_1.07.02.bin
'


    pwd=$PWD

    echo $l


    git config --global user.name "Importer Script"
    git config --global user.email nobody@localhost


    ls buildroot || { \
        tag=2013.05
        url=https://github.com/buildroot/buildroot
        #url=https://github.com/tizenteam/buildroot
        git clone $url 
        cd $pwd/buildroot ;
        git reset --hard $tag ; \
            cd $pwd
        url=https://buildroot.org/downloads/buildroot-$tag.tar.gz
        basename=$(basename -- "$url")
        wget -c $url
        unp buildroot-$tag.tar.gz
        mv $pwd/buildroot/.git* $pwd/buildroot-$tag
        cd $pwd/buildroot-$tag
        git add .

        git commit -am "import: $basename

Origin: $url
"

        #mv .gitignore ~/
        git add -f .

        git commit -am "import: $basename (ignored)

Origin: $url
" ||:

        mv  $pwd/buildroot-$tag/.git*  $pwd/buildroot
    }


    cd $pwd
    ls .git || cp -rfa $PWD/buildroot/.git* $HOME 

    for url in $l ; do
        cd $pwd
        wget -c $url
        basename=$(basename -- "$url")
        rm -rf $pwd/tmp/$basename/
        mkdir -p $pwd/tmp/$basename/
        cd $pwd/tmp/$basename/
        unp ~/$basename
        cd */package/.. || { unp *gz && cd */package/.. ; }
        mv ~/.git ./
        cp -a  ~/.gitignore ./
        git add .

        git commit -am "import: $basename

Origin: $url
"

        rm .gitignore
        git add -f .
        cp -a  ~/.gitignore ./

        git commit -am "import: $basename (ignored)

Origin: $url
" ||:

        mv .git* ~/
        #git revert -m 'revert:' HEAD
    done
}


dl_()
{

    mkdir -p dl && cd dl

    cat<<EOF>urls.lst
https://releases.linaro.org/archive/13.03/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.7-2013.03-20130313_linux.tar.bz2

https://distfiles.dereferenced.org/pkgconf/pkgconf-0.8.9.tar.bz2

http://archive.ubuntu.com/ubuntu/pool/main/n/net-tools/net-tools_1.60.orig.tar.gz
http://lmde-mirror.gwendallebihan.net/latest/pool/main/n/net-tools/net-tools_1.60-25.diff.gz
http://ftp.embeddedarm.com/ftp/mirror/yocto/net-tools_1.60-25.diff.gz

http://pkgs.fedoraproject.org/repo/pkgs/php/php-5.4.19.tar.bz2/f06f99b9872b503758adab5ba7a7e755/php-5.4.19.tar.bz2
http://museum.php.net/php5/php-5.4.19.tar.bz2

http://pkgs.fedoraproject.org/repo/pkgs/shadow-utils/shadow-4.1.5.1.tar.bz2/a00449aa439c69287b6d472191dc2247/shadow-4.1.5.1.tar.bz2

http://pkgs.fedoraproject.org/repo/pkgs/logrotate/logrotate-3.7.9.tar.gz/eeba9dbca62a9210236f4b83195e4ea5/logrotate-3.7.9.tar.gz
EOF

    wget -c -i urls.lst
    url=http://download.wdc.com/nas/MyPassportWireless_1.07.02.bin
    wget -c $url
    cd -

}


build_()
{
    dl_

    if [ ! -e  output/target/version ]; then
        unp "dl/MyPassportWireless_1.07.02.bin"
        mkdir -p "output/target/etc/"

        cp -av ./fwupg_images/version.packages output/target/etc/
        cp -av ./fwupg_images/version output/target/etc/
    fi

    mkdir -p outputFWupg/build
    dst="outputFWupg/build/linux-custom"
#   [ -e "$dst" ] ||  ln -fs  ../linux-am33x_devel $dst
    sh -x -e ./buildfwupg_img.sh
}


rebuild_()
{
    ls .git build.sh || exit 1
    rm -rf *
    git reset --hard 
    build_
}


main_()
{
    b=$(date -u)
    rebuild_
    date -u
    echo $u
}


[ "" != "$1" ] || main_
$@
