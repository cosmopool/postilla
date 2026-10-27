# Comandos do app. O conteúdo vem de ../postilla-content (pipeline em Zig).
#
#   make test      testes do pipeline e do app (analyze + flutter test)
#   make build     builds de release do Android e do iOS (sem assinatura)
#   make content   regera os pacotes no postilla-content e copia para cá

CONTENT ?= ../postilla-content

.PHONY: all fetch content test test-content test-app analyze build build-ios build-android run clean

all: test

# Copia os pacotes fixados no content.lock e confere o sha256.
fetch:
	dart run tool/fetch_content.dart

# Regera dict e stories. Se o sha256 mudar, atualize o content.lock com out/SHA256SUMS.
content:
	cd $(CONTENT) && zig build run -- dict && zig build run -- stories && zig build run -- pack
	$(MAKE) fetch

test: test-content test-app

test-content:
	cd $(CONTENT) && zig build test

test-app: fetch analyze
	flutter test

analyze:
	dart analyze

build: build-android build-ios

build-android: fetch
	flutter build apk --release

build-ios: fetch
	flutter build ios --release --no-codesign

run: fetch
	flutter run

clean:
	flutter clean
	rm -rf assets/content
