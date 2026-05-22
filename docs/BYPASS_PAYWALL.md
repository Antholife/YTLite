# Bypass paywall YouTube Plus 5.2.1 (étape par étape)

Tu gardes le **.deb officiel 5.2.1** + un petit tweak **PaywallBypass** compilé chez toi.

## Prérequis Mac

1. **Xcode Command Line Tools**
2. **Homebrew**
3. **Theos** (compilateur tweaks iOS)
4. **ldid** (signature du binaire, via brew)

## Étape 0 — Vérifier les outils

```bash
xcode-select -p
brew --version
```

Si `xcode-select` échoue :

```bash
xcode-select --install
```

## Étape 1 — Homebrew (si pas installé)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Puis les outils utiles :

```bash
brew install ldid xz git
```

## Étape 2 — Installer Theos

```bash
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git "$THEOS"
```

SDK iOS pour compiler :

```bash
cd /tmp
git clone --depth 1 https://github.com/theos/sdks.git
cp -r sdks/iPhoneOS16.5.sdk "$THEOS/sdks/"
```

Ajoute dans `~/.zshrc` :

```bash
export THEOS=~/theos
export PATH="$THEOS/bin:$PATH"
```

Puis :

```bash
source ~/.zshrc
```

## Étape 3 — Télécharger le .deb officiel 5.2.1

```bash
mkdir -p ~/ytlite-work && cd ~/ytlite-work
curl -L -O "https://github.com/dayanch96/YTLite/releases/download/v5.2.1/com.dvntm.ytlite_5.2.1_iphoneos-arm.deb"
ls -la com.dvntm.ytlite_5.2.1_iphoneos-arm.deb
```

Tu dois voir ~7 Mo.

## Étape 4 — Compiler PaywallBypass

Ouvre le dossier du fork (celui avec `PaywallBypass/`).

```bash
cd "/Users/Antholife/Library/Mobile Documents/com~apple~CloudDocs/Dev/YTLite/PaywallBypass"
make clean package FINALPACKAGE=1
```

Le `.deb` bypass est dans :

```bash
ls -la packages/*.deb
cp packages/*.deb ~/ytlite-work/paywallbypass.deb
```

## Étape 5 — Installer sur l’iPhone

### Jailbreak (Sileo / Zebra)

1. Installe d’abord `com.dvntm.ytlite_5.2.1_iphoneos-arm.deb`
2. Puis `paywallbypass.deb`
3. Respring

### Sideload (TrollStore + TrollFools ou IPA cyan)

Injecte **les deux** `.deb` dans l’IPA YouTube (voir étape 6).

## Étape 6 — IPA avec les 2 debs (option sideload)

Si tu as **cyan** / workflow GitHub : il faut `ytplus.deb` + `paywallbypass.deb` dans la commande d’injection.

Exemple local avec cyan :

```bash
pipx install --force https://github.com/asdfzxcvbn/pyzule-rw/archive/main.zip
cyan -i youtube.ipa -o YouTubePlus_patched.ipa -uwef \
  com.dvntm.ytlite_5.2.1_iphoneos-arm.deb \
  paywallbypass.deb \
  -n YouTube -b com.google.ios.youtube
```

## Vérification

1. Ouvre YouTube → Réglages → section YouTube Plus
2. Plus d’alerte « log in with Patreon » bloquante
3. Les toggles doivent réagir normalement

## Dépannage

| Problème | Piste |
|----------|--------|
| `make: Theos not found` | `export THEOS=~/theos` + `source ~/.zshrc` |
| SDK manquant | recopier `iPhoneOS16.5.sdk` dans `$THEOS/sdks/` |
| Bypass ne marche pas | respring ; réinstaller bypass **après** YTLite |
| Encore paywall | le check n’utilise peut‑être pas `isAuthorized` → voir Ghidra (plan B) |

## Plan B — patch du dylib (avancé)

1. Installer [Ghidra](https://ghidra-sre.org/)
2. Extraire le deb (`ar x` + `tar --lzma -xf data.tar.lzma`)
3. Analyser `YTLite.dylib`, chercher `isAuthorized`
4. Patcher pour retourner toujours `1`, `ldid -S`, repacker le deb
