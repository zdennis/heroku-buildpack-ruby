require "language_pack/shell_helpers"
module LanguagePack::Installers; end

# This is a base module that is later included by other
# classes such as LanguagePack::Installers::HerokuRubyInstaller
#
module LanguagePack::Installers::RubyInstaller
  include LanguagePack::ShellHelpers

  DEFAULT_BIN_DIR = "bin"

  def self.installer(ruby_version)
    if ruby_version.rbx?
      LanguagePack::Installers::RbxInstaller
    else
      LanguagePack::Installers::HerokuRubyInstaller
    end
  end

  def install(ruby_version, install_dir)
    warn_outdated_version(ruby_version)
    fetch_unpack(ruby_version, install_dir)
    setup_binstubs(install_dir)
  end

  def setup_binstubs(install_dir)
    FileUtils.mkdir_p DEFAULT_BIN_DIR
    run("ln -s ruby #{install_dir}/bin/ruby.exe")

    Dir["#{install_dir}/bin/*"].each do |vendor_bin|
      # for Ruby 2.6.0+ don't symlink the Bundler bin so our shim works
      next if vendor_bin.include?("bundle")
      run("ln -s ../#{vendor_bin} #{DEFAULT_BIN_DIR}")
    end
  end

  # Emits a warning if there are more recent
  # versions of a ruby version. For example
  # if an app is using 2.6.1 and 2.6.2 is the latest
  # it will report that 2.6.2 is available
  def warn_outdated_version(ruby_version)
    increment = 1
    while @fetcher.exists?("#{ruby_version.next_logical_version(increment)}.tgz")
      increment += 1
    end

    return false unless increment > 1

    max_version = ruby_version.next_logical_version(increment - 1)

        warn(<<-WARNING)
There is a more recent Ruby version available for you to use:

#{max_version}

The latest version will include security and bug fixes, we always recommend
running the latest version of your minor release.

See https://devcenter.heroku.com/articles/ruby-versions for all available versions.
WARNING
    return max_version
  end
end
