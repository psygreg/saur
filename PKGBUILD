# Maintainer: Psygreg -- https://github.com/psygreg
pkgname=saur
pkgver=0.1
pkgrel=1
pkgdesc="Install manager for Arch-based distributions. Supports pacman, flatpak and AUR packages."
arch=('any')
license=('GPL')
depends=('pacman' 'git' 'makepkg' 'base-devel')
source=('saur.sh')
md5sums=('SKIP')

package() {
  install -Dm755 "$srcdir/saur.sh" "$pkgdir/usr/bin/saur"
}
