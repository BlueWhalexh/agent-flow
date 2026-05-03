#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_BRANCH="main"
DEFAULT_IMAGE_TAG="latest"
DEFAULT_SERVICES="core-workflow-java"
DEFAULT_DEPLOY_WORKFLOW="Deploy Production"
DEFAULT_BUILD_WORKFLOW="GHCR Build Images"

branch=""
commit_message=""
services="$DEFAULT_SERVICES"
image_tag="$DEFAULT_IMAGE_TAG"
deploy_workflow_name="$DEFAULT_DEPLOY_WORKFLOW"
build_workflow_name="$DEFAULT_BUILD_WORKFLOW"
auto_deploy=true
auto_commit=true

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release-gh.sh -m "feat: xxx" [options]

Options:
  -m, --message           Git commit message
  -b, --branch            Branch to push, default is current branch
  -s, --services          Services to deploy, default is core-workflow-java
  -t, --tag               Image tag, default is latest
  -w, --workflow          Deploy workflow name, default is "Deploy Production"
      --build-workflow    Build workflow name, default is "GHCR Build Images"
      --no-deploy         Only commit and push
      --no-commit         Only push and deploy
  -h, --help              Show help

Examples:
  ./scripts/release-gh.sh -m "feat: update xiaomi flow"
  ./scripts/release-gh.sh -m "fix: console hub" -s "console-hub"
  ./scripts/release-gh.sh --no-deploy -m "chore: save progress"
  ./scripts/release-gh.sh --no-commit --branch main -s "core-workflow-java"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      commit_message="${2:-}"
      shift 2
      ;;
    -b|--branch)
      branch="${2:-}"
      shift 2
      ;;
    -s|--services)
      services="${2:-}"
      shift 2
      ;;
    -t|--tag)
      image_tag="${2:-}"
      shift 2
      ;;
    -w|--workflow)
      deploy_workflow_name="${2:-}"
      shift 2
      ;;
    --build-workflow)
      build_workflow_name="${2:-}"
      shift 2
      ;;
    --no-deploy)
      auto_deploy=false
      shift
      ;;
    --no-commit)
      auto_commit=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Current directory is not a Git repository"
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
branch="${branch:-$current_branch}"

if [[ "$auto_commit" == true ]]; then
  if [[ -z "$commit_message" ]]; then
    echo "Commit message is required in auto-commit mode: -m \"your message\""
    exit 1
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    echo "[1/5] Changes detected, preparing commit"
    git add -A
    if [[ -n "$(git diff --cached --name-only)" ]]; then
      git commit -m "$commit_message"
    else
      echo "No staged changes to commit"
    fi
  else
    echo "[1/5] No local changes, skip commit"
  fi
else
  echo "[1/5] Auto commit skipped"
fi

echo "[2/5] Pushing branch to origin/$branch"
git push origin "$branch"

if [[ "$auto_deploy" != true ]]; then
  echo "[3/5] Deploy skipped by option"
  exit 0
fi

if [[ "$branch" != "$DEFAULT_BRANCH" ]]; then
  echo "[3/5] Branch is not main, deploy skipped"
  echo "Reason: production images are pushed only after merge into main."
  echo "Suggested command after merge:"
  echo "  ./scripts/release-gh.sh --no-commit --branch main -s \"$services\" -t \"$image_tag\""
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[3/5] gh CLI not found, cannot trigger deploy automatically"
  echo "Run the workflow manually in GitHub Actions:"
  echo "  workflow: $deploy_workflow_name"
  echo "  branch:   $branch"
  echo "  tag:      $image_tag"
  echo "  services: $services"
  exit 0
fi

echo "[3/5] Waiting for build workflow: $build_workflow_name"
head_sha="$(git rev-parse HEAD)"
build_run_id=""

for _ in {1..12}; do
  build_run_id="$(gh run list \
    --workflow "$build_workflow_name" \
    --branch "$branch" \
    --limit 10 \
    --json databaseId,headSha \
    --jq ".[] | select(.headSha == \"$head_sha\") | .databaseId" | head -n 1 || true)"

  if [[ -n "$build_run_id" ]]; then
    break
  fi
  sleep 5
done

if [[ -z "$build_run_id" ]]; then
  echo "Could not find a build run for commit $head_sha"
  echo "Please confirm it manually in GitHub Actions:"
  echo "  workflow: $build_workflow_name"
  echo "  branch:   $branch"
  echo "  commit:   $head_sha"
  exit 1
fi

gh run watch "$build_run_id" --exit-status

echo "[4/5] Triggering deploy workflow: $deploy_workflow_name"
gh workflow run "$deploy_workflow_name" \
  --ref "$branch" \
  -f image_tag="$image_tag" \
  -f services="$services"

echo "[5/5] Latest deploy run"
gh run list --workflow "$deploy_workflow_name" --limit 1

echo "Release command finished."
