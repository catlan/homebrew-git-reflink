# homebrew-git-reflink

Git with `git worktree add` populating new worktrees via copy-on-write
clones (reflinks) on APFS, from the `worktree-reflink` branch of
https://github.com/catlan/git, while the series is under review upstream.

    brew install catlan/git-reflink/git-reflink
    export PATH="$(brew --prefix git-reflink)/bin:$PATH"

The formula is keg-only so it does not replace Homebrew's or Apple's git
until you put it on your PATH. `brew install --HEAD catlan/git-reflink/git-reflink`
builds the current branch tip instead of the pinned tag.
