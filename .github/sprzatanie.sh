#!/bin/bash
# Odcina historię gałęzi main starszą niż rok. Najstarsza zachowana zmiana staje się początkiem historii;
# jej pliki są kompletne, więc nic z obecnego stanu nie ginie.
set -euo pipefail
CUTOFF="${CUTOFF:-$(date -d '1 year ago' +%s)}"
OLD_HEAD=$(git rev-parse HEAD)
KEEP=$(git rev-list --reverse --since="@$CUTOFF" HEAD | head -n 1)
if [ -z "$KEEP" ]; then echo "Brak zmian z ostatniego roku – nic nie robię."; exit 0; fi
if ! git rev-parse -q --verify "$KEEP^" >/dev/null; then echo "Historia ma mniej niż rok – nic nie robię."; exit 0; fi
echo "Usuwam $(git rev-list --count "$KEEP^") starych zmian, zostaje $(git rev-list --count "$KEEP^..HEAD")."
git replace --graft "$KEEP"
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f -- HEAD
git replace -d "$KEEP"
if [ "${DRY_RUN:-}" = "1" ]; then echo "(próba – bez wysyłania)"; exit 0; fi
git push --force-with-lease="main:$OLD_HEAD" origin HEAD:main
