# Overzetten naar een offline Windows-machine

Deze config draait op een machine zonder internet, mits je de artefacten die
normaal gedownload worden vooraf meeneemt. Nexus (npm-proxy) dekt een groot deel
daarvan; de rest is handwerk.

Uitgangspunt: de werk-PC heeft **node + npm met `.npmrc` naar Nexus**, een werkende
`pip install`, en een Neovim 0.12.x installatie.

> **Scripts.** `scripts\export-offline.ps1` en `scripts\import-offline.ps1` doen
> stap 1 en 2 hieronder automatisch. Draai ze eerst met `-DryRun`. De handmatige
> beschrijving hieronder blijft de bron van waarheid -- en je terugval als
> PowerShell op de werk-PC dichtstaat.

## Windows-paden

| Wat | Pad |
|---|---|
| Config | `%LOCALAPPDATA%\nvim` |
| Plugins | `%LOCALAPPDATA%\nvim-data\lazy` |
| Mason | `%LOCALAPPDATA%\nvim-data\mason` |
| Treesitter-parsers | `%LOCALAPPDATA%\nvim-data\site\parser` |

## 1. Meenemen vanaf een machine mét internet

### a. De config zelf

```
git bundle create nvim-config.bundle --all
```

Op de doelmachine: `git clone nvim-config.bundle %LOCALAPPDATA%\nvim`.
Een gewone map-kopie werkt ook, maar dan verlies je de git-historie en kun je
er later niets meer in terugdraaien.

### b. Plugins (~86 MB)

Kopieer de hele `lazy`-map. De inhoud is Lua/vimscript en dus
platform-onafhankelijk. Twee uitzonderingen, allebei gecompileerd:

- `telescope-fzf-native.nvim` — de macOS `.so` werkt niet op Windows. Dit is
  géén blokkade: `init.lua` laadt de extensie met `pcall`, dus zonder build valt
  Telescope terug op de standaard sorter. Wil je hem wel, bouw dan op Windows
  met de cmake-variant uit de README van die plugin.
- `LuaSnip` (jsregexp) — optioneel, alleen nodig voor regex-transformaties in
  snippets.

### c. Mason-registry (536 KB) — de sleutel tot Nexus

```
%LOCALAPPDATA%\nvim-data\mason\registries\
```

Kopieer die map mee. Het is platte JSON, platform-onafhankelijk. Zonder deze map
probeert Mason zijn index van GitHub te halen en faalt alles; mét deze map kan
hij via Nexus installeren.

### d. Treesitter-parsers

Deze moeten **op een Windows-machine mét internet** gebouwd worden — grammars
worden per stuk als tarball van GitHub gehaald, dus Nexus helpt hier niet. Daar
heb je eenmalig voor nodig: de `tree-sitter` CLI (0.26.1+, via winget of scoop,
*niet* via npm) en een C-compiler.

Draai daar een `nvim` met deze config, wacht tot alle parsers gecompileerd zijn,
en kopieer dan de inhoud van `site\parser\` (bestanden heten `<lang>.so`, ook op
Windows) naar de offline machine.

### e. De drie GitHub-binaries

Mason haalt `ruff`, `stylua` en `lua-language-server` van GitHub-releases, niet van
npm of PyPI -- die drie moeten dus mee (~49 MB). Let op dat `ruff` hier de
uitzondering is: die staat ook op PyPI, maar Mason gebruikt de GitHub-release.

Wat juist **niet** mee hoeft, en waarom dat de moeite van het weglaten waard is:

| bron | omvang | |
|---|---|---|
| npm (7 pakketten) | ~517 MB | Nexus levert dit |
| PyPI (`basedpyright`) | ~281 MB | `pip install` werkt daar |

Blind de hele `mason`-map kopieren is dus ruim 800 MB waarvan het grootste deel op
de doelmachine gewoon opnieuw op te halen is. Het complete pakket komt selectief
uit op zo'n 160 MB.

## 2. Op de offline machine

1. Config, `lazy`, `mason\registries` en `site\parser` op hun plek zetten.
2. `nvim` starten. Lazy vindt alle plugins al op schijf en probeert niets te
   downloaden.
3. `:MasonToolsInstall` — dit trekt de npm-pakketten via Nexus binnen:
   `typescript-language-server`, `angular-language-server`,
   `vscode-langservers-extracted` (goed voor html/css/json/eslint) en
   `prettierd`.

## 3. Verifiëren

```
:checkhealth
:Mason                  " staat alles op installed?
:lua =vim.lsp.get_clients()
```

Open daarna een `.component.html` uit een echt Angular-project en controleer:

```
:lua =vim.bo.filetype                                    " htmlangular
:lua =vim.treesitter.language.get_lang(vim.bo.filetype)  " angular
:lua =#vim.lsp.get_clients({ bufnr = 0 })                " >= 1 (angularls)
```

`angularls` start alleen waar een `angular.json` of `nx.json` staat, en zoekt
`@angular/language-service` + `typescript` eerst in de `node_modules` van het
project zelf. In een Angular-repo met een gevulde `node_modules` werkt hij dus
ook zonder de Mason-install.

## Bekende scherpe randen

- **Mason en registry-updates.** Nagekeken in de broncode: een mislukte refresh
  is niet fataal. De synchrone variant draait in een `pcall` en geeft simpelweg
  `false` terug, en een refresh wordt sowieso overgeslagen zolang de gekopieerde
  cache jonger is dan `registry_cache.duration` en de checksum klopt. Wil je het
  helemaal uitsluiten, zet de refresh dan uit in `init.lua`:

  ```lua
  require('mason').setup { registry_cache = { refresh = false } }
  ```

  Bijwerken gaat dan alleen nog handmatig via `:MasonUpdate` -- op een offline
  machine precies wat je wilt.
- **Nieuwe parsers.** Elke taal die je later toevoegt aan `ensure_installed` in
  `init.lua` heeft opnieuw een build op een Windows-machine mét internet nodig.
- **Niet migreren naar `vim.pack`.** Upstream kickstart is inmiddels van
  lazy.nvim af, maar dat lost hier niets op: ook `vim.pack` cloned van GitHub.
  Het kost je wel je lazy-loading (`keys`, `event`) en het bindt de config aan
  Neovim 0.12+, wat op een beheerde werk-PC geen gegeven is.
