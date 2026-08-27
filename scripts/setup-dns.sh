#!/usr/bin/env bash
# Point haanasewing.com at GitHub Pages via the Cloudflare API.
#
# Needs a token with  Zone:Read + DNS:Edit  on haanasewing.com, read from
#   ~/.config/cloudflare/dns-token
# (create at https://dash.cloudflare.com/profile/api-tokens -> Edit zone DNS)
#
# Idempotent: re-running updates in place rather than duplicating.
# Pass --dry-run to print what it would do and change nothing.

set -euo pipefail

ZONE="haanasewing.com"
TARGET_CNAME="oobeid123.github.io"
TOKEN_FILE="$HOME/.config/cloudflare/dns-token"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

A_IPS=(185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153)
AAAA_IPS=(2606:50c0:8000::153 2606:50c0:8001::153 2606:50c0:8002::153 2606:50c0:8003::153)

[ -r "$TOKEN_FILE" ] || { echo "no token at $TOKEN_FILE"; exit 1; }
CF=$(tr -d '[:space:]' < "$TOKEN_FILE")

api() { curl -sS -H "Authorization: Bearer $CF" -H "Content-Type: application/json" "$@"; }

ok() { python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)"; }

echo "verifying token..."
api https://api.cloudflare.com/client/v4/user/tokens/verify \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
if not d.get('success'):
    print('  token rejected:', d.get('errors')); sys.exit(1)
print('  token ok, status =', d['result']['status'])"

ZID=$(api "https://api.cloudflare.com/client/v4/zones?name=$ZONE" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if not d.get('success') or not d['result']:
    print('ZONE_NOT_FOUND'); sys.exit(0)
print(d['result'][0]['id'])")
[ "$ZID" = "ZONE_NOT_FOUND" ] && { echo "zone $ZONE not visible to this token"; exit 1; }
echo "zone id: $ZID"

echo
echo "existing records on the apex and www:"
api "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records?per_page=100" | python3 -c "
import sys,json
d=json.load(sys.stdin)
rows=[r for r in d['result'] if r['name'] in ('$ZONE','www.$ZONE')]
if not rows: print('  (none)')
for r in rows:
    print(f\"  {r['type']:<6} {r['name']:<26} {r['content'][:46]:<46} proxied={r['proxied']}  id={r['id']}\")"

upsert() {  # type name content
  local type=$1 name=$2 content=$3
  local existing
  existing=$(api "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records?type=$type&name=$name" \
    | python3 -c "
import sys,json
d=json.load(sys.stdin)
want='''$content'''
for r in d.get('result',[]):
    if r['content'].lower()==want.lower(): print(r['id']); break
")
  local body
  body=$(python3 -c "
import json
print(json.dumps({'type':'$type','name':'$name','content':'$content',
                  'ttl':1,'proxied':False,
                  'comment':'GitHub Pages — haanasewing-site'}))")
  if [ "$DRY" = 1 ]; then
    echo "  DRY  ${existing:+update }${existing:-create} $type $name -> $content"
    return
  fi
  if [ -n "$existing" ]; then
    api -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records/$existing" \
      --data "$body" | ok && echo "  updated  $type $name -> $content" \
      || echo "  FAILED   $type $name -> $content"
  else
    api -X POST "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records" \
      --data "$body" | ok && echo "  created  $type $name -> $content" \
      || echo "  FAILED   $type $name -> $content"
  fi
}

echo
echo "writing records (all DNS-only / grey cloud — GitHub issues its own cert):"
for ip in "${A_IPS[@]}";    do upsert A    "$ZONE" "$ip"; done
for ip in "${AAAA_IPS[@]}"; do upsert AAAA "$ZONE" "$ip"; done
upsert CNAME "www.$ZONE" "$TARGET_CNAME"

echo
echo "done. next:"
echo "  1. wait for propagation:  dig +short $ZONE"
echo "  2. then enforce HTTPS:"
echo "     gh api -X PUT repos/oobeid123/haanasewing-site/pages -F https_enforced=true"
