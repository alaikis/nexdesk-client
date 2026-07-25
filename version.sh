#!/bin/bash
# Version Management Script for NEX
# Usage: ./version.sh [major|minor|patch|alpha|beta|rc|show]

set -e

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo "Current version: $CURRENT_VERSION"

# Parse version components
if [[ "$CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z]+)(\.([0-9]+))?)?$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
  PRERELEASE="${BASH_REMATCH[5]}"
  PRERELEASE_NUM="${BASH_REMATCH[7]}"
else
  echo "ERROR: Invalid version format: $CURRENT_VERSION"
  exit 1
fi

# Bump version based on argument
case "$1" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    PRERELEASE=""
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    PRERELEASE=""
    ;;
  patch)
    PATCH=$((PATCH + 1))
    PRERELEASE=""
    ;;
  alpha)
    if [[ "$PRERELEASE" == "alpha" ]]; then
      PRERELEASE_NUM=$((PRERELEASE_NUM + 1))
    else
      PATCH=$((PATCH + 1))
      PRERELEASE="alpha"
      PRERELEASE_NUM=1
    fi
    ;;
  beta)
    if [[ "$PRERELEASE" == "beta" ]]; then
      PRERELEASE_NUM=$((PRERELEASE_NUM + 1))
    else
      PATCH=$((PATCH + 1))
      PRERELEASE="beta"
      PRERELEASE_NUM=1
    fi
    ;;
  rc)
    if [[ "$PRERELEASE" == "rc" ]]; then
      PRERELEASE_NUM=$((PRERELEASE_NUM + 1))
    else
      PATCH=$((PATCH + 1))
      PRERELEASE="rc"
      PRERELEASE_NUM=1
    fi
    ;;
  show)
    exit 0
    ;;
  *)
    echo "Usage: $0 [major|minor|patch|alpha|beta|rc|show]"
    echo ""
    echo "Examples:"
    echo "  $0 major    # 1.2.3-alpha.1 → 2.0.0"
    echo "  $0 minor    # 1.2.3-alpha.1 → 1.3.0"
    echo "  $0 patch    # 1.2.3-alpha.1 → 1.2.4"
    echo "  $0 alpha    # 1.2.3-alpha.1 → 1.2.3-alpha.2"
    echo "  $0 beta     # 1.2.3-alpha.1 → 1.2.4-beta.1"
    echo "  $0 rc       # 1.2.3-alpha.1 → 1.2.4-rc.1"
    exit 1
    ;;
esac

# Build new version string
if [[ -n "$PRERELEASE" ]]; then
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}-${PRERELEASE}.${PRERELEASE_NUM}"
else
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

echo "New version: $NEW_VERSION"

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update pubspec.yaml
sed -i "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml

echo "Version bumped to $NEW_VERSION"
echo ""
echo "To release this version:"
echo "  git add VERSION pubspec.yaml CHANGELOG.md"
echo "  git commit -m \"chore(release): v${NEW_VERSION}\""
echo "  git tag v${NEW_VERSION}"
echo "  git push origin main --tags"
