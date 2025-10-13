# Maintainer: execrooted <your@email.com>

pkgname=droplet
pkgver=0.1.0
pkgrel=1
pkgdesc="A colorful terminal weather animation tool written in Rust (rain and snow effects)"
arch=('x86_64')
url="https://github.com/execrooted/droplet"
license=('MIT')
depends=()
makedepends=('rust' 'cargo')
source=("$url/archive/refs/tags/v$pkgver.tar.gz"
        "install.sh"
        "uninstall.sh")
sha256sums=('SKIP'
            'SKIP'
            'SKIP')

build() {
    cd "$srcdir/$pkgname-$pkgver"
    cargo build --release --locked
}

package() {
    cd "$srcdir/$pkgname-$pkgver"
    install -Dm755 "target/release/$pkgname" "$pkgdir/usr/local/bin/$pkgname"
    install -Dm644 "README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 "LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm755 "install.sh" "$pkgdir/usr/share/$pkgname/install.sh"
    install -Dm755 "uninstall.sh" "$pkgdir/usr/share/$pkgname/uninstall.sh"
}

