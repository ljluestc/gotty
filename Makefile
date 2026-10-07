OUTPUT_DIR = ./builds
GIT_COMMIT = `git rev-parse HEAD | cut -c1-7`
VERSION = 2.0.0-alpha.3
BUILD_OPTIONS = -ldflags "-X main.Version=$(VERSION) -X main.CommitID=$(GIT_COMMIT)"

gotty: main.go server/*.go webtty/*.go backend/*.go Makefile
	godep go build ${BUILD_OPTIONS}

.PHONY: asset
asset: bindata/static/js/gotty-bundle.js bindata/static/index.html bindata/static/favicon.png bindata/static/css/index.css bindata/static/css/xterm.css bindata/static/css/xterm_customize.css
	go-bindata -prefix bindata -pkg server -ignore=\\.gitkeep -o server/asset.go.new bindata/...
	@# Old or incompatible go-bindata versions don't generate AssetDir, which breaks the build
	@# with `undefined: AssetDir`. Check before replacing server/asset.go.
	@grep -q '^func AssetDir(' server/asset.go.new || { \
		echo "error: \`$$(command -v go-bindata)\` generated code without AssetDir." >&2; \
		echo "Install a compatible go-bindata with \`make tools\` and make sure it comes first in your PATH." >&2; \
		rm -f server/asset.go.new; exit 1; }
	mv server/asset.go.new server/asset.go
	gofmt -w server/asset.go

.PHONY: all
all: asset gotty

bindata:
	mkdir bindata

bindata/static: bindata
	mkdir bindata/static

bindata/static/index.html: bindata/static resources/index.html
	cp resources/index.html bindata/static/index.html

bindata/static/favicon.png: bindata/static resources/favicon.png
	cp resources/favicon.png bindata/static/favicon.png

bindata/static/js: bindata/static
	mkdir -p bindata/static/js


bindata/static/js/gotty-bundle.js: bindata/static/js js/dist/gotty-bundle.js
	cp js/dist/gotty-bundle.js bindata/static/js/gotty-bundle.js

bindata/static/css: bindata/static
	mkdir -p bindata/static/css

bindata/static/css/index.css: bindata/static/css resources/index.css
	cp resources/index.css bindata/static/css/index.css

bindata/static/css/xterm_customize.css: bindata/static/css resources/xterm_customize.css
	cp resources/xterm_customize.css bindata/static/css/xterm_customize.css

bindata/static/css/xterm.css: bindata/static/css js/node_modules/xterm/dist/xterm.css
	cp js/node_modules/xterm/dist/xterm.css bindata/static/css/xterm.css

js/node_modules/xterm/dist/xterm.css:
	cd js && \
	npm install

js/dist/gotty-bundle.js: js/src/* js/node_modules/webpack
	cd js && \
	`npm bin`/webpack

js/node_modules/webpack:
	cd js && \
	npm install

tools:
	go get github.com/tools/godep
	go get github.com/mitchellh/gox
	go get github.com/tcnksm/ghr
	go install github.com/go-bindata/go-bindata/v3/go-bindata@v3.1.3

test:
	if [ `go fmt $(go list ./... | grep -v /vendor/) | wc -l` -gt 0 ]; then echo "go fmt error"; exit 1; fi

cross_compile:
	GOARM=5 gox -os="darwin linux freebsd netbsd openbsd" -arch="386 amd64 arm" -osarch="!darwin/arm" -output "${OUTPUT_DIR}/pkg/{{.OS}}_{{.Arch}}/{{.Dir}}"

targz:
	mkdir -p ${OUTPUT_DIR}/dist
	cd ${OUTPUT_DIR}/pkg/; for osarch in *; do (cd $$osarch; tar zcvf ../../dist/gotty_${VERSION}_$$osarch.tar.gz ./*); done;

shasums:
	cd ${OUTPUT_DIR}/dist; sha256sum * > ./SHA256SUMS

release:
	ghr -c ${GIT_COMMIT} --delete --prerelease -u yudai -r gotty pre-release ${OUTPUT_DIR}/dist
