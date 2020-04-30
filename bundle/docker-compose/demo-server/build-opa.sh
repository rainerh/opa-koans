#!/usr/bin/env bash
set -e
workspace=$(cd "$(dirname "$0")" && pwd -P)

bundleDir="$workspace"/../..

opa_revision() {
    REVISION_BUNDLE=$(git log --abbrev-commit --pretty=format:"%h" "$bundleDir"/example | head -n1)
    REVISION_DISCOVERY=$(git log --abbrev-commit --pretty=format:"%h" "$bundleDir"/discovery | head -n1)

    # update .manifest revision
    echo "Checking revision of rbac's .manifest..."
    jq --arg rid "$REVISION_BUNDLE" '.revision = $rid' "$bundleDir"/example/.manifest | tee tmp_revison
    mv tmp_revison "$bundleDir"/example/.manifest
    echo "Updated revision of rbac's .manifest"

    cat >"$workspace"/revision.env <<EOF
# demo-server env_file: revision of each bundle, used for etag
REVISION_BUNDLE=$REVISION_BUNDLE
REVISION_DISCOVERY=$REVISION_DISCOVERY
EOF
}
opa_bundle() {
    dockerComposeDir="$workspace"/..
    # bundle
    cd "$bundleDir"/example || exit
    find . -type f ! -name "*.tar.gz" -print0 | tar -cvzf rbac.tar.gz --null -T -
    mv rbac.tar.gz "$dockerComposeDir/demo-server"
    echo "RBAC files bundled!"

    # discovery
    cd "$bundleDir"/discovery || exit
    find . -type f ! -name "*.tar.gz" -print0 | tar -cvzf discovery.tar.gz --null -T -
    mv discovery.tar.gz "$dockerComposeDir/demo-server"
    echo "Discovery files bundled!"
}

{
    opa_revision
    echo "start build opa bundle ..."
    opa_bundle
    echo "start build demo-app ..."
    cd "$workspace" || exit
}
