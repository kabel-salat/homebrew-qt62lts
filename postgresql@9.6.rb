class PostgresqlAT96 < Formula
  desc "Relational database management system"
  homepage "https://www.postgresql.org/"
  version = "9.6.24"
  url "https://ftp.postgresql.org/pub/source/v#{version}/postgresql-#{version}.tar.bz2"
  sha256 "aeb7a196be3ebed1a7476ef565f39722187c108dd47da7489be9c4fcae982ace"
  license "PostgreSQL"

  livecheck do
    url "https://ftp.postgresql.org/pub/source/"
    regex(%r{href=["']?v?(9\.6(?:\.\d+)*)/?["' >]}i)
  end

  keg_only :versioned_formula

  option "with-cassert", "Enable assertion checks (for debugging)"
  deprecated_option "enable-cassert" => "with-cassert"

  # https://www.postgresql.org/support/versioning/
  # deprecate! date: "2021-11-11", because: :unsupported

  depends_on "gettext"
  depends_on "openldap"
  depends_on "openssl@1.1"
  depends_on "readline"

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-dtrace
      --enable-nls
      --with-bonjour
      --with-gssapi
      --with-ldap
      --with-libxml
      --with-libxslt
      --with-openssl
      --with-uuid=e2fs
      --with-pam
      --with-perl
      XML2_CONFIG=:
    ]

    # Add include and library directories of dependencies, so that
    # they can be used for compiling extensions.  Superenv does this
    # when compiling this package, but won't record it for pg_config.
    deps = %w[gettext openldap openssl@1.1 readline]
    with_includes = deps.map { |f| Formula[f].opt_include }.join(":")
    with_libraries = deps.map { |f| Formula[f].opt_lib }.join(":")
    args << "--with-includes=#{with_includes}"
    args << "--with-libraries=#{with_libraries}"

    extra_version = ""

    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "./configure", *args
    system "make", "install-world"
  end

  def caveats
    <<~EOS
      To use this PostgreSQL installation, do one or more of the following:

      - Call all programs explicitly with #{opt_prefix}/bin/...
      - Add #{opt_bin} to your PATH
      - brew link -f #{name}
      - Install the postgresql-common package

      To access the man pages, do one or more of the following:
      - Refer to them by their full path, like `man #{opt_share}/man/man1/psql.1`
      - Add #{opt_share}/man to your MANPATH
      - brew link -f #{name}
    EOS
  end

  test do
    system "#{bin}/initdb", "pgdata"
  end
end
