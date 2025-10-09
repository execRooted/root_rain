pkgname=raindrops
pkgver=0.1.0
pkgrel=1
pkgdesc="An aesthetic rain CLI program written in Rust"
arch=('x86_64')
url="https://github.com/execRooted/raindrops.git"
license=('MIT')
depends=()
makedepends=('rust')
source=()        # empty for local builds
sha256sums=()

build() {
    cargo build --release --locked
}

package() {
    install -Dm755 target/release/raindrops "$pkgdir/usr/bin/raindrops"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
