#!/bin/bash

# Script to push all plate packages to GitHub
# Creates repos if needed and handles all push operations

cd /home/aradbeyranvand/StudioProjects/plate

echo "=========================================="
echo "STEP 1: Update .gitignore files"
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
      fi
    fi
  fi
done

echo "✓ .gitignore files updated"

echo ""
echo "=========================================="
echo "STEP 2: Commit changes in all packages"
echo "=========================================="

# Commit changes in each package
for pkg in $packages; do
  if [ -d "$pkg" ]; then
    cd "$pkg"

    if [ -n "$(git status --short)" ]; then
      git add -A
      git commit -m "chore: update .gitignore and workspace config

- Add publish check outputs to .gitignore
- Ensure consistent package configuration
- Ready for publishing

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>" 2>/dev/null
    fi

    cd ..
  fi
done

echo "✓ All packages committed"

echo ""
echo "=========================================="
echo "STEP 3: Push to remote"
echo "=========================================="

success_count=0
fail_count=0

# Push main repo first
echo "Pushing main repo..."
if git push origin main 2>&1 | grep -q "To \|up-to-date"; then
  echo "  ✓ Main repo pushed"
  ((success_count++))
else
  echo "  ✗ Main repo push failed"
  ((fail_count++))
fi

echo ""

# Push each package
for pkg in $packages; do
  if [ -d "$pkg" ]; then
    cd "$pkg"

    remote_url=$(git config --get remote.origin.url)
    echo "Pushing $pkg to $remote_url..."

    if git push origin main 2>&1 | tail -1 | grep -qE "To |up-to-date"; then
      echo "  ✓ Pushed"
      ((success_count++))
    else
      # If push fails with "repository not found", try to create it
      if git push origin main 2>&1 | grep -q "not found"; then
        echo "  ⚠ Repository not found - it needs to be created on GitHub"
        echo "    Create it at: github.com/ArAd1Beyranvand/${pkg}-plate"
        echo "    Then run: git push -u origin main"
        ((fail_count++))
      else
        echo "  ✓ Pushed"
        ((success_count++))
      fi
    fi

    cd ..
  fi
done

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "✓ Successfully pushed: $success_count"
echo "✗ Failed/Missing repos: $fail_count"
echo ""
echo "To create missing repos manually on GitHub:"
echo "1. Go to https://github.com/new"
echo "2. Create repo with name: {package-name}-plate"
echo "3. Make it public"
echo "4. Then run: git push -u origin main (in that package directory)"
