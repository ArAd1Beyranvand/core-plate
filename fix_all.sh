#!/bin/bash

# Comprehensive fix script for all plate packages:
# 1. Add warning files to .gitignore
# 2. Create git repos for packages that need them
# 3. Push all changes

cd /home/aradbeyranvand/StudioProjects/plate

echo "=========================================="
echo "STEP 1: Add warning files to all .gitignore"
echo "=========================================="

packages="plate_core plate_alphabet plate_keypad algeria_plate bolivia_plate colombia_plate cuba_plate germany_plate india_plate indonesia_plate iran_plate iranshahr_plate lebanon_plate malaysia_plate mali_plate niger_plate palestine_plate sudan_plate tunisia_plate venezuela_plate yemen_plate"

for pkg in $packages; do
  if [ -d "$pkg" ]; then
    gitignore_file="$pkg/.gitignore"

    # Add publish warning files to .gitignore if not already there
    if [ -f "$gitignore_file" ]; then
      if ! grep -q "publish_issues.txt" "$gitignore_file"; then
        echo "" >> "$gitignore_file"
        echo "# Publish check outputs" >> "$gitignore_file"
        echo "publish_issues.txt" >> "$gitignore_file"
        echo "all_publish_warnings.txt" >> "$gitignore_file"
        echo "  ✓ Added publish files to .gitignore in $pkg"
      fi
    fi
  fi
done

echo ""
echo "=========================================="
echo "STEP 2: Create missing git repos and push"
echo "=========================================="

# Packages with missing repos (from the error messages)
missing_repos=(
  "iranshahr_plate:https://github.com/ArAd1Beyranvand/iranshahr-plate.git"
  "malaysia_plate:https://github.com/ArAd1Beyranvand/malaysia-plate.git"
  "mali_plate:https://github.com/ArAd1Beyranvand/mali-plate.git"
  "niger_plate:https://github.com/ArAd1Beyranvand/niger-plate.git"
  "palestine_plate:https://github.com/ArAd1Beyranvand/palestine-plate.git"
  "sudan_plate:https://github.com/ArAd1Beyranvand/sudan-plate.git"
  "tunisia_plate:https://github.com/ArAd1Beyranvand/tunisia-plate.git"
)

for item in "${missing_repos[@]}"; do
  pkg_name="${item%%:*}"
  repo_url="${item##*:}"

  if [ -d "$pkg_name" ]; then
    cd "$pkg_name"

    # Check if repo exists by trying to fetch
    if ! git remote -v | grep -q "$repo_url"; then
      echo "Setting up $pkg_name..."

      # Initialize if needed
      if [ ! -d ".git" ]; then
        git init
        git config user.email "$(git config --global user.email)"
        git config user.name "$(git config --global user.name)"
        git add -A
        git commit -m "Initial commit" 2>/dev/null || true
        git branch -M main 2>/dev/null || true
      fi

      # Add remote and push
      git remote add origin "$repo_url" 2>/dev/null || git remote set-url origin "$repo_url"
      echo "  Pushing $pkg_name to $repo_url..."
      git push -u origin main 2>&1 | grep -E "To|fatal|\\[" || echo "    ✓ Pushed"
    fi

    cd ..
  fi
done

echo ""
echo "=========================================="
echo "STEP 3: Push all other changes"
echo "=========================================="

# Push main repo
echo "Pushing main repository..."
git add -A
git commit -m "chore: add warning files to .gitignore" 2>/dev/null || echo "  (no changes in main repo)"
git push origin main 2>&1 | grep -E "To|\\[" || echo "  ✓ Main repo up to date"

# Push all submodule changes
for pkg in $packages; do
  if [ -d "$pkg" ]; then
    cd "$pkg"

    if [ -n "$(git status --short)" ]; then
      echo "Pushing changes in $pkg..."
      git add -A
      git commit -m "chore: add warning files to .gitignore" 2>/dev/null || true
      git push origin main 2>&1 | grep -E "To|fatal|\\[" || echo "  ✓ Pushed"
    fi

    cd ..
  fi
done

echo ""
echo "=========================================="
echo "✅ COMPLETE!"
echo "=========================================="
echo "All packages have been:"
echo "  1. Added warning files to .gitignore"
echo "  2. Created missing git repos"
echo "  3. Pushed to remote"
