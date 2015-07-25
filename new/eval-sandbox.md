How to create an image
======================

Airi uses [Docker](https://www.docker.com) and [Arch Linux](https://www.archlinux.org) to provide an eval sandbox beacuse Arch Linux provides the most-updated version so there is no need to build Ruby.

If you have an Arch Linux install, you can use `pacstrap` script from `extra/arch-install-scripts`.

    # mkdir archimage
    # pacstrap -cd archimage coreutils busybox ruby
    # install -dm644 assets/escaper.rb archimage/evalrb/escaper.rb
      (you can remove some files)
    # rm -rf archimage/usr/share/{doc,man}/* archimage/usr/include/* archimage/var/cache/* archimage/lib/*/*.a


If you don't have it, you can also [use the Arch Linux bootstrap image](https://wiki.archlinux.org/index.php/Install_from_existing_Linux#Method_1:_Using_the_Bootstrap_Image_.28recommended.29).

    # wget https://mirrors.kernel.org/archlinux/iso/[date]/archlinux-bootstrap-[date]-x86_64.tar.gz
    # mkdir archbootstrap
    # tar xf archlinux-bootstrap-[date]-x86_64.tar.gz -C archbootstrap
    # nano archbootstrap/root.x86_64/etc/pacman.d/mirrorlist # select a repository mirror
    # sed -i 's/SigLevel *=.*$/SigLevel = Never/g' archbootstrap/root.x86_64/etc/pacman.conf # disable signature checking
    # archbootstrap/root.x86_64/usr/bin/arch-chroot archbootstrap/root.x86_64
      (in chroot)
    # pacman -Syu  --noconfirm ruby busybox
    # pacman -Rcsn --noconfirm systemd pacman
    # cd /bin
    # for command in $(busybox --list)
    > do
    >   [ ! -e $command ] && busybox ln -s busybox $command
    > done
      (you can remove some files)
    # rm -rf /usr/share/{doc,man}/* /usr/include/* /var/cache/* /lib/*/*.a
    # exit # exit chroot
      (note that the root filesystem is on archbootstrap/root.x86_64)
    # ln -s archbootstrap/root.x86_64 archimage
    # install -dm644 assets/escaper.rb archimage/evalrb/escaper.rb

For upgrading or installing other packages, run `pacstrap -cd archimage ruby` or `pacstrap -cd archimage <pkg1> <pkg2> ...` on where you run `pacstrap` or create the image again if you have no `pacstrap`.

Now you can create a Docker image

    # tar -cf- -C archimage .  | docker import - evalrb-sandbox



