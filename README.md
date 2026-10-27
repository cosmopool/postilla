# Postilla

Histórias em italiano com dicionário monolíngue, offline. App Flutter (iOS e Android). O que entra em cada versão está em [docs/roadmap.md](docs/roadmap.md); specs em [docs/](docs/).

## Conteúdo

O conteúdo vem do repositório irmão `../postilla-content` (pipeline em Zig). O `content.lock` fixa versão e sha256 de cada pacote.

```
cd ../postilla-content
zig build run -- fetch     # fontes em data/
zig build run -- dict
zig build run -- stories
zig build run -- pack      # out/*.db.gz e out/SHA256SUMS
```

Depois, aqui:

```
dart run tool/fetch_content.dart   # copia para assets/content/ e confere o sha256
```

Um pacote novo pede atualizar o `content.lock` com os valores de `out/SHA256SUMS`.

## Rodar e testar

```
flutter run
dart analyze
flutter test
```

Os testes usam os mesmos pacotes de `assets/content/` (ARQ-93): rode o `fetch_content` antes.
