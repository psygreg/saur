# Maintainer: Psygreg -- https://github.com/psygreg
pkgname=saur
pkgver=1.1
pkgrel=1
pkgdesc="Install manager for Arch-based distributions. Supports pacman, flatpak and AUR packages."
arch=('any')
license=('GPL')
depends=('pacman' 'git' 'base-devel')
optdepends=('flatpak: For optional flatpak package management'
            'timeshift: For optional system backup functionality')
source=('saur.sh')
md5sums=('SKIP')

package() {
  install -Dm755 "$srcdir/saur.sh" "$pkgdir/usr/bin/saur"
}
