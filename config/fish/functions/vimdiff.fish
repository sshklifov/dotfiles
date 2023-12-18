function acceptFile
        if not test -f $argv[1]
                return 1
        end

        set tmp (string split "." $argv[1])
        if not set -q tmp
                return 1
        end
        if string match -q $tmp[-1] "png"
                return 1
        end
        return 0
end

function vimdiff --description 'Open changed files in neovim'
        set project (git rev-parse --show-toplevel)
        if test $status -ne 0
                return 1
        end
        if set -q argv[1]
                set commitish $argv[1]
        else
                set commitish ""
        end
        for f in (eval "git diff $commitish --name-only")
                set file "$project/$f"
                if acceptFile $file
                        set files $files $file
                end
        end
        if set -q files[1]
            echo $files | xargs nvim -c ":tabdo lefta Gdiffsplit $commitish" -p
        else
                echo "No changes"
                return 1
        end
end
