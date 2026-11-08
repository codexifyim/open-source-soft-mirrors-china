#!/usr/bin/env bash

set -u

SAMPLES=3                               # latency samples per mirror
BYTES=$((10 * 1024 * 1024))             # 10 MB per bandwidth test
SMALL_PATH="ubuntu/dists/noble/Release" # ~150 KB, good for TTFB
LARGE_PATH="ubuntu/ls-lR.gz"            # large, good for bandwidth

MIRRORS=(
  "Tsinghua|https://mirrors.tuna.tsinghua.edu.cn"
  "USTC|https://mirrors.ustc.edu.cn"
  "Aliyun|https://mirrors.aliyun.com"
  "Tencent|https://mirrors.cloud.tencent.com"
  "Huawei|https://mirrors.huaweicloud.com"
  "163|https://mirrors.163.com"
  "BFSU|https://mirror.bfsu.edu.cn"
  "NJU|https://mirrors.nju.edu.cn"
  "SJTU|https://mirror.sjtu.edu.cn"
  "ZJU|https://mirrors.zju.edu.cn"
  "LZU|https://mirrors.lzu.edu.cn"
  "CQU|https://mirrors.cqu.edu.cn"
  "HIT|https://mirrors.hit.edu.cn"
  "PKU|https://mirrors.pku.edu.cn"
  "XJTU|https://mirrors.xjtu.edu.cn"
  "Sohu|https://mirrors.sohu.com"
)

median() { sort -n | awk '{a[NR]=$1} END{print (NR%2)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2}'; }

printf "%-10s %-42s %10s %12s\n" "MIRROR" "URL" "TTFB(ms)" "SPEED(MB/s)"
printf '%s\n' "--------------------------------------------------------------------------------"

declare -a summary=()
for entry in "${MIRRORS[@]}"; do
  name="${entry%%|*}"
  url="${entry#*|}"
  small="$url/$SMALL_PATH"
  large="$url/$LARGE_PATH"

  # --- Latency: 3 samples, take median ---
  lats=()
  for _ in $(seq 1 "$SAMPLES"); do
    t=$(curl -fL -o /dev/null -s -m 8 -w '%{time_starttransfer}' "$small" 2>/dev/null || true)
    [[ -z "$t" || "$t" =~ ^0(\.0+)?$ ]] && {
      lats=()
      break
    }
    lats+=("$t")
  done

  if [[ ${#lats[@]} -eq 0 ]]; then
    printf "%-10s %-42s %10s %12s\n" "$name" "$url" "FAIL" "-"
    continue
  fi

  med=$(printf '%s\n' "${lats[@]}" | median)
  ms=$(awk -v t="$med" 'BEGIN{printf "%d", t*1000}')

  # --- Bandwidth: ranged download of first 10 MB ---
  sp=$(curl -fL -r 0-$((BYTES - 1)) -o /dev/null -s -m 40 -w '%{speed_download}' "$large" 2>/dev/null || echo 0)
  mbps=$(awk -v s="$sp" 'BEGIN{printf "%.2f", s/1048576}')

  printf "%-10s %-42s %10s %12s\n" "$name" "$url" "$ms" "$mbps"
  summary+=("$ms|$mbps|$name|$url")
done

echo
echo "=== Ranked fastest first (by latency, then speed) ==="
printf '%s\n' "${summary[@]}" | sort -t'|' -k1,1n -k2,2nr |
  awk -F'|' '{printf "%2d. %-10s %6s ms  %7s MB/s  %s\n", NR, $3, $1, $2, $4}'
