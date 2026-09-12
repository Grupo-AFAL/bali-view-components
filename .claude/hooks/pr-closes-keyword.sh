#!/bin/bash
#
# PreToolUse (Bash) — impide abrir o editar una PR cuyo cuerpo intente cerrar un
# issue EN ESPAÑOL.
#
# Por qué existe: GitHub solo cierra el issue al mergear si el cuerpo de la PR
# trae una de sus palabras clave, y TODAS son en inglés —`Closes`, `Fixes`,
# `Resolves` y sus variantes—. «Cierra #123» es texto muerto: se lee igual de
# bien, no cierra nada, y el issue se queda abierto sin que nadie se entere
# hasta que alguien lo barre a mano. Pasó decenas de veces.
#
# Esto no es un recordatorio, es una compuerta: el comando no corre.
#
# Contrato del hook: recibe el JSON de la llamada por stdin y decide por código
# de salida — 0 deja pasar, 2 bloquea y le devuelve a Claude lo que se imprima
# en stderr. Cualquier otro fallo (jq ausente, JSON raro) deja pasar: una
# compuerta rota no puede volverse un tapón para todo lo demás.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

ENTRADA=$(cat)
COMANDO=$(printf '%s' "$ENTRADA" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0

# Solo mira los dos comandos que publican un cuerpo de PR.
printf '%s' "$COMANDO" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+(create|edit)' || exit 0

# El verbo en español, seguido de un issue. `arregla|corrige|resuelve|cierra`
# son los cuatro que se escriben solos cuando uno viene redactando en español.
PATRON='(^|[^[:alnum:]])([Cc]ierra|[Cc]ierran|[Rr]esuelve|[Rr]esuelven|[Cc]orrige|[Aa]rregla)[[:space:]]+#[0-9]+'

# El cuerpo viaja de dos maneras: `--body-file ruta` o `--body "texto"`. La
# primera es la que usa este repo; la segunda se revisa sobre el comando mismo.
CUERPO=""
RUTA=$(printf '%s' "$COMANDO" | sed -nE "s/.*--body-file[[:space:]]+('([^']*)'|\"([^\"]*)\"|([^[:space:]]+)).*/\2\3\4/p")
if [ -n "$RUTA" ] && [ -f "$RUTA" ]; then
  CUERPO=$(cat "$RUTA")
else
  CUERPO="$COMANDO"
fi

printf '%s' "$CUERPO" | grep -Eq "$PATRON" || exit 0

OFENSA=$(printf '%s' "$CUERPO" | grep -Eo "$PATRON" | head -3 | sed 's/^/    /')

cat >&2 <<EOF
El cuerpo de la PR intenta cerrar un issue en español y GitHub no lo entiende:

$OFENSA

GitHub SOLO cierra el issue al mergear con sus palabras clave, y todas son en
inglés: Closes / Fixes / Resolves (y closed/fixed/resolved). «Cierra #123» se
lee bien y no cierra nada — el issue se queda abierto.

Cámbialo a «Closes #123» (el resto del cuerpo puede seguir en español) y vuelve
a correr el comando.
EOF
exit 2
