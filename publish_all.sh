#!/bin/bash

# Publish all plate packages to pub.dev

cd /home/aradbeyranvand/StudioProjects/plate

packages="plate_core plate_alphabet plate_keypad algeria_plate bolivia_plate colombia_plate cuba_plate germany_plate india_plate indonesia_plate iran_plate iranshahr_plate lebanon_plate malaysia_plate mali_plate niger_plate palestine_plate sudan_plate tunisia_plate venezuela_plate yemen_plate"

echo "=========================================="
echo "Publishing all packages to pub.dev"
echo "=========================================="
echo ""

published=0
failed=0
already_exists=0

for pkg in $packages; do
  if [ -d "$pkg" ]; then
    echo ">>> $pkg"
    cd "$pkg"

    # Run publish with automatic confirmation
    result=$(echo "y" | flutter pub publish 2>&1)

    if echo "$result" | grep -q "Successfully uploaded"; then
      echo "  ✅ Published"
      ((published++))
    elif echo "$result" | grep -q "already exists"; then
      echo "  ℹ️  Version already exists on pub.dev"
      ((already_exists++))
    else
      echo "  ❌ Failed"
      ((failed++))
      # Show error
      echo "$result" | grep -E "error|Error|ERROR|failed|Failed" | head -3
    fi

    cd ..
    echo ""
  fi
done

echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "✅ Published: $published"
echo "ℹ️  Already exists: $already_exists"
echo "❌ Failed: $failed"
echo ""
echo "Total: $((published + already_exists + failed))/$((${#packages[@]}))"
