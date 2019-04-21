# frozen_string_literal: true
#
require 'language_pack/fetcher'

class LanguagePack::Helpers::GelWrapper
  VERSION = "0.2.0"
  DOWNLOAD_URL = "https://github.com/gel-rb/gel/archive/"
  PATH = "vendor/gel-#{VERSION}"
  GEL_STORE = "vendor/gel/gems"
  GEL_CACHE = "vendor/gel/cache"

  def gel?
    @gel ||= !File.read("Gemfile.lock").include?("BUNDLED WITH")
  end

  def initialize(gemfile_path = "Gemfile")
    @fetcher = LanguagePack::Fetcher.new(DOWNLOAD_URL)
  end

  def path_env
    "#{PATH}/exe:#{GEL_STORE}/bin"
  end

  def rubylib_env
    "#{PATH}/lib/gel/compatibility"
  end

  def install(dir)
    path = "#{dir}/vendor"
    FileUtils.mkdir_p(path)

    Dir.chdir(path) do
      @fetcher.fetch_untar("v#{VERSION}.tar.gz")
    end

    path
  end

  def version
    VERSION
  end
end
