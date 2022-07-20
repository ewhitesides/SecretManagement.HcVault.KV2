#!/bin/bash

#vscode resets .bashrc to their default at container start,
#and then we append the following to switch to starship
echo 'eval "$(starship init bash)"' >> ~/.bashrc

#basic config for starship
#container disabled = true removes ugly stop sign icon - personal preference
mkdir -p "$HOME/.config"
cat > $HOME/.config/starship.toml <<EOF
[container]
disabled = true
EOF
