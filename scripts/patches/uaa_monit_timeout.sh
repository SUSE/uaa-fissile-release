#!/bin/sh

# On lower-end machines (e.g. vagrant box for development), UAA might
# take too long to start.  Extend the timeout to avoid that.

set -o errexit -o nounset

PATCH_DIR="/var/vcap/jobs-src/uaa/"
SENTINEL="${PATCH_DIR}/${0##*/}.sentinel"

if [ -f "${SENTINEL}" ]; then
  exit 0
fi

cd "${PATCH_DIR}"
patch --strip=3 --force <<'PATCH'
diff --git a/jobs/uaa/monit b/jobs/uaa/monit
index d7bd9dc..4524ca1 100644
--- a/jobs/uaa/monit
+++ b/jobs/uaa/monit
@@ -5,6 +5,6 @@ check process uaa
   group vcap
   if failed port 8989 protocol http
     request "/healthz"
-    with timeout 60 seconds for 15 cycles
+    with timeout 600 seconds for 15 cycles
   then restart
PATCH

touch "${SENTINEL}"
