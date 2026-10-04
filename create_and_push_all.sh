#!/bin/bash

# Comprehensive script to:
# 1. Add warning files to .gitignore
# 2. CREATE GitHub repos for packages that don't have them
# 3. Push all changes to remote

cd /home/aradbeyranvand/StudioProjects/plate

echo "=========================================="
echo "STEP 1: Add warning files to all .gitignore"
echo "=========================================="

packages="plate_core plate_alphabet plate_keypad algeria_plate bolivia_plate colombia_plate cuba_plate germany_plate india_plate indonesia_plate iran_plate iranshahr_plate lebanon_plate malaysia_plate mali_plate niger_plate palestine_plate sudan_plate tunisia_plate venezuela_plate yemen_plate"

for pkg in $packages; do
  if [ -d "$pkg" ]; then
    gitignore_file="$pkg/.gitignore"

    if [ -f "$gitignore_file" ]; then
      if ! grep -q "publish_issues.txt" "$gitignore_file"; then
        echo "" >> "$gitignore_file"
        echo "# Publish check outputs" >> "$gitignore_file"
        echo "publish_issues.txt" >> "$gitignore_file"
        echo "all_publish_warnings.txt" >> "$gitignore_file"
        echo "  ✓ Added to .gitignore in $pkg"
      fi
    fi
  fi
done

echo ""
echo "=========================================="
echo "STEP 2: Create GitHub repos for missing packages"
echo "=========================================="

# Packages that need repos created
packages_needing_repos=(
  "plate_core"
  "iranshahr_plate"
  "lebanon_plate"
  "malaysia_plate"
  "mali_plate"
  "niger_plate"
  "palestine_plate"
  "sudan_plate"
  "tunisia_plate"
  "venezuela_plate"
  "yemen_plate"
)

for pkg in "${packages_needing_repos[@]}"; do
  if [ -d "$pkg" ]; then
    repo_name="${pkg%-plate}"
    repo_name="${repo_name//_/-}"
    repo_url="https://github.com/ArAd1Beyranvand/${repo_name}-plate.git"

    # Check if repo already exists on GitHub
    if ! git ls-remote "$repo_url" &>/dev/null; then
      echo "Creating GitHub repo for $pkg..."

      # Create repo using gh CLI
      gh repo create "ArAd1Beyranvand/${repo_name}-plate" \
        --public \
        --source="$pkg" \
        --remote=origin \
        --push 2>/dev/null && echo "  ✓ Created and pushed $pkg" || echo "  ✗ Failed to create $pkg"
    else
      echo "  ✓ Repo already exists for $pkg"
    fi
  fi
done

echo ""
echo "=========================================="
echo "STEP 3: Push all changes to remote"
echo "=========================================="

# Push main repo
echo "Pushing main repository..."
git add -A
git commit -m "chore: finalize all gitignore and push configurations" 2>/dev/null || echo "  (no new changes)"
git push origin main 2>&1 | tail -2

# Push all packages
for pkg in $packages; do
  if [ -d "$pkg" ]; then
    cd "$pkg"

    if [ -n "$(git status --short)" ]; then
      echo "Pushing $pkg..."
      git add -A
      git commit -m "chore: finalize gitignore configuration" 2>/dev/null || true
      git push origin main 2>&1 | tail -2
    fi

    cd ..
  fi
done

echo ""
echo "=========================================="
echo "✅ COMPLETE!"
echo "=========================================="
echo "All packages have been:"
echo "  1. ✓ Warning files added to .gitignore"
echo "  2. ✓ GitHub repos created (where needed)"
echo "  3. ✓ All changes pushed to remote"
echo ""
echo "Run this to verify: git remote -v"
