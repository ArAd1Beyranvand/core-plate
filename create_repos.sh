#!/bin/bash

# Create missing GitHub repositories for all plate packages

cd /home/aradbeyranvand/StudioProjects/plate

echo "=========================================="
echo "Creating GitHub repositories"
echo "=========================================="

# List of all plate packages and their repo names
repos=(
  "plate_core:plate-core"
  "plate_alphabet:plate-alphabet"
  "plate_keypad:plate-keypad"
  "algeria_plate:algeria-plate"
  "bolivia_plate:bolivia-plate"
  "colombia_plate:colombia-plate"
  "cuba_plate:cuba-plate"
  "germany_plate:germany-plate"
  "india_plate:india-plate"
  "indonesia_plate:indonesia-plate"
  "iran_plate:iran-plate"
  "iranshahr_plate:iranshahr-plate"
  "lebanon_plate:lebanon-plate"
  "malaysia_plate:malaysia-plate"
  "mali_plate:mali-plate"
  "niger_plate:niger-plate"
  "palestine_plate:palestine-plate"
  "sudan_plate:sudan-plate"
  "tunisia_plate:tunisia-plate"
  "venezuela_plate:venezuela-plate"
  "yemen_plate:yemen-plate"
)

created_count=0
skipped_count=0

for item in "${repos[@]}"; do
  pkg_dir="${item%%:*}"
  repo_name="${item##*:}"
  full_repo="ArAd1Beyranvand/${repo_name}"

  if [ -d "$pkg_dir" ]; then
    echo ""
    echo "Checking $repo_name..."

    # Check if repo exists on GitHub
    if gh repo view "$full_repo" &>/dev/null; then
      echo "  ✓ Already exists"
      ((skipped_count++))
    else
      echo "  Creating $repo_name..."

      # Create the repo
      if gh repo create "$full_repo" --public --source="$pkg_dir" --remote=origin --push 2>&1 | head -5; then
        echo "  ✓ Created and pushed"
        ((created_count++))
      else
        echo "  ⚠ Failed to create (trying alternative method...)"

        # Alternative: create without pushing first
        if gh repo create "$full_repo" --public 2>&1 | grep -q "created"; then
          echo "  ✓ Created on GitHub"

          # Now push from the directory
          cd "$pkg_dir"
          git remote set-url origin "https://github.com/$full_repo.git" 2>/dev/null || \
          git remote add origin "https://github.com/$full_repo.git" 2>/dev/null

          if git push -u origin main 2>&1 | grep -qE "To |up-to-date"; then
            echo "  ✓ Pushed to GitHub"
            ((created_count++))
          else
            echo "  ✗ Push failed"
          fi
          cd ..
        else
          echo "  ✗ Failed to create"
        fi
      fi
    fi
  fi
done

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Created: $created_count repos"
echo "Skipped: $skipped_count repos (already exist)"
echo ""
echo "Now push all packages with:"
echo "  bash push_all_packages.sh"
