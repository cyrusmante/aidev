#!/usr/bin/env bash
# create-test-repo.sh — Creates a minimal Express app in ./test-repo for local testing.
# Called automatically by test-local.sh if no target repo exists.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$SCRIPT_DIR/test-repo"

echo "[setup] Creating test-repo at $REPO"

mkdir -p "$REPO/src" "$REPO/tests"

# ── package.json ──────────────────────────────────────────────────────────────
cat > "$REPO/package.json" <<'EOF'
{
  "name": "test-repo",
  "version": "1.0.0",
  "description": "Minimal Express app for AI Dev Agent testing",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "test": "node --test tests/"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {}
}
EOF

# ── src/app.js ────────────────────────────────────────────────────────────────
cat > "$REPO/src/app.js" <<'EOF'
const express = require('express');

const app = express();
app.use(express.json());

// Routes will be added here

const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
EOF

# ── tests/app.test.js ────────────────────────────────────────────────────────
cat > "$REPO/tests/app.test.js" <<'EOF'
// Minimal test file using Node's built-in test runner (no extra deps needed)
const { test } = require('node:test');
const assert = require('node:assert/strict');

// Placeholder test — the agent will add real tests for the /hello endpoint
test('app module loads without error', () => {
  const app = require('../src/app');
  assert.ok(app, 'app should export something');
});
EOF

# ── README.md ─────────────────────────────────────────────────────────────────
cat > "$REPO/README.md" <<'EOF'
# test-repo

Minimal Express app used for local AI Dev Agent testing.

## Setup

```bash
npm install
```

## Run

```bash
npm start
```

## Test

```bash
npm test
```

## Structure

```
src/
  app.js        — Express app (exported for testing)
tests/
  app.test.js   — Tests using Node's built-in test runner
```
EOF

# ── Git init ──────────────────────────────────────────────────────────────────
cd "$REPO"

if [ ! -d ".git" ]; then
  git init
  git checkout -b main
  git add .
  git commit -m "chore: initial minimal Express app skeleton"
  echo "[setup] Git repo initialised on branch 'main'"
fi

# Install deps so npm test works
if command -v npm &>/dev/null; then
  echo "[setup] Running npm install..."
  npm install --silent
fi

echo "[setup] test-repo is ready at $REPO"
