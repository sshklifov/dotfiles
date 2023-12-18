function nvim --description 'Open nvim without borders'
    set termbg (kitty @get-colors | grep ^background | tr -s " " | cut -d " " -f 2)
    set nvimbg (/usr/bin/nvim --headless "+highlight Normal" "+q" 2>&1 | tr -d '\n' | sed 's/.*guibg=\(.*\)/\1/')

    kitty @set-colors background=$nvimbg
    kitty @set-font-size +1
    /usr/bin/nvim $argv
    kitty @set-font-size -- -1
    kitty @set-colors background=$termbg
end

