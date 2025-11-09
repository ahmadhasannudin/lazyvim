#!/bin/bash
# Fix Neovim permission issues caused by root-owned files

echo "Fixing Neovim file permissions..."
echo "This script will change ownership of Neovim data/state files from root to your user."
echo ""

# Fix data directory
sudo chown -R ahmadhasanudin:staff ~/.local/share/nvim/

# Fix state directory
sudo chown -R ahmadhasanudin:staff ~/.local/state/nvim/

# Fix cache directory if needed
sudo chown -R ahmadhasanudin:staff ~/.cache/nvim/ 2>/dev/null

echo ""
echo "Done! All Neovim files now owned by ahmadhasanudin:staff"
echo ""
echo "You can now restart Neovim without permission errors."
