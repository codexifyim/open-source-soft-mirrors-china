Mirror Benchmark Script

Tests the most popular Chinese mirrors for latency (TTFB) and download bandwidth, then ranks them


# How it works

1. Latency — fetches a small Release file three times, takes the median TTFB (avoids one-off outliers).

2. Bandwidth — downloads the first 10 MB of ls-lR.gz with a Range request, so you get a real throughput number without pulling a whole ISO.

3. Ranking — sorts by TTFB first (feels more "snappy" for small requests like apt update), then by speed as tiebreaker.



# Notes / tweaks

Add mirrors: append to the MIRRORS array — format is "name|https://url".

Test a different distro: if you mostly use Debian, change SMALL_PATH/LARGE_PATH to debian/dists/trixie/Release and debian/ls-lR.gz.

FAIL on a mirror: usually means that mirror doesn't carry Ubuntu (rare) or is temporarily down. It does not mean the mirror is unreachable — try a package it does carry.

Bandwidth test returns 0: some servers don't honor Range requests on ls-lR.gz. The latency column is still valid.

Run 3–5 times at different times of day — results swing noticeably during peak hours (roughly 20:00–23:00 CST).


