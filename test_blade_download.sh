#!/bin/bash
# Test if blade.php download works

# Simulate what happens when you press the download key
echo "Testing blade.php download simulation..."

# Check the keymap code
echo "Current download keymap (line 131-133):"
sed -n '131,133p' lua/config/keymaps.lua
