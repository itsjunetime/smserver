# To Install

### To build from source:

1. Clone this repository
1. `cd` into the directory where the `make.sh` script is located
1. Run `./make.sh` with the following flags:  \
	`-n` if this is your first time running \
	`-i` to make a `.ipa` package \
	`-d` to make a `.deb` package \
	`-l` to compile the iOS 12 and lower version as well \
	`-m` to minify the web interface files \
	`-v` for verbose output

For example, if you'd like to make a `.deb` package and you've never run this before, run `./make.sh -dn`
