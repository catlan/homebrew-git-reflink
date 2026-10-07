class GitReflink < Formula
  desc "Git with 'worktree add' populating new worktrees via copy-on-write clones"
  homepage "https://github.com/catlan/git/tree/worktree-reflink"
  url "https://github.com/catlan/git/archive/refs/tags/v2.56.0-reflink1.tar.gz"
  version "2.56.0-reflink1"
  sha256 "68a11240c5c8e3bcb3fac322f48689d6e7dd066363b4da152eb1bc5e0a43a2b3"
  license all_of: [
    "GPL-2.0-only",
    "GPL-2.0-or-later",
    "LGPL-2.1-or-later",
    "BSD-3-Clause",
    "MIT",
  ]
  head "https://github.com/catlan/git.git", branch: "worktree-reflink"

  keg_only "it shadows the git formula; put it first on your PATH to use it"

  depends_on "gettext" => :build
  depends_on "pkgconf" => :build
  depends_on "pcre2"

  uses_from_macos "curl"
  uses_from_macos "expat"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "linux-headers@5.15" => :build
    depends_on "openssl@3"
  end

  def install
    ENV["NO_FINK"] = "1"
    ENV["NO_DARWIN_PORTS"] = "1"
    ENV["PYTHON_PATH"] = which("python3")
    ENV["PERL_PATH"] = which("perl")
    ENV["USE_LIBPCRE2"] = "1"
    ENV["INSTALL_SYMLINKS"] = "1"
    ENV["LIBPCREDIR"] = formula_opt_prefix("pcre2")
    ENV["V"] = "1"

    args = %W[
      prefix=#{prefix}
      sysconfdir=#{etc}
      CC=#{ENV.cc}
      CFLAGS=#{ENV.cflags}
      LDFLAGS=#{ENV.ldflags}
      NO_TCLTK=1
      NO_RUST=1
      NO_PERL=1
      GIT_VERSION=#{version}
    ]

    args += if OS.mac?
      %w[NO_OPENSSL=1 APPLE_COMMON_CRYPTO=1]
    else
      %W[NO_APPLE_COMMON_CRYPTO=1 OPENSSLDIR=#{formula_opt_prefix("openssl@3")}]
    end

    # Let the installed git find its helpers from the opt prefix.
    inreplace "Makefile", /(-DFALLBACK_RUNTIME_PREFIX=")[^"]+/, "\\1#{opt_prefix}"

    system "make", "install", *args

    return unless OS.mac?

    cd "contrib/credential/osxkeychain" do
      system "make", *args
      (libexec/"git-core").install "git-credential-osxkeychain"
    end
  end

  def caveats
    <<~EOS
      This git is installed keg-only. To use it instead of the system or
      Homebrew git, add it to the front of your PATH:
        export PATH="#{opt_bin}:$PATH"

      New worktrees are populated with copy-on-write clones on APFS (and
      Btrfs/XFS on Linux); set worktree.reflink=false to turn that off.
    EOS
  end

  test do
    assert_match "worktree.reflink", shell_output("#{bin}/git help --config-for-completion")
    system bin/"git", "init", "-q", "repo"
    cd "repo" do
      (testpath/"repo/file").write("content\n" * 1000)
      system bin/"git", "add", "file"
      system bin/"git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "init"
      system bin/"git", "worktree", "add", "-q", "--detach", "../wt", "HEAD"
      assert_equal (testpath/"repo/file").read, (testpath/"wt/file").read
      assert_empty shell_output("#{bin}/git -C ../wt status --porcelain")
    end
  end
end
