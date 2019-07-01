# Queries S3 in the background to determine
# what versions are supported so they can be recommended
# to the user
#
# Example:
#
#   ruby_version = LanguagePack::RubyVersion.new("ruby-2.2.5")
#   outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
#     ruby_version: ruby_version,
#     fetcher: LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, "heroku-16")
#   )
#
#   outdated.call
#   puts outdated.suggested_ruby_minor_version
#   #=> "ruby-2.2.10"
class LanguagePack::Helpers::OutdatedRubyVersion
  attr_reader :ruby_version

  def initialize(ruby_version: , fetcher:)
    @ruby_version = ruby_version
    @fetcher      = fetcher

    @minor_versions = [ruby_version]
    @eol_versions = []

    # @minor_versions = 10.times.each_with_object({}) { |i,h| h[ruby_version.next_logical_version(i + 1)] = i + 1 }
    @threads = []
  end

  def suggested_ruby_minor_version
    return ruby_version unless can_check?

    suggested_version = @ruby_version
    @minor_versions.detect do |version|
      suggested_version = version  if version
      !version # keep going until we find a falsey version
    end

    suggested_version
  end

  def eol?
    return false unless can_check?

    true if @eol_versions.length > 3
  end

  # Account for preview releases
  def maybe_eol?
    return false unless can_check?

    true if @eol_versions.length > 2
  end

  def call
    return unless can_check?

    check_minor_versions(1..5)
    check_eol_versions_major
    check_eol_versions_minor
    self
  end

  def can_check?
    return false if ruby_version.patchlevel_is_significant?
    return false if ruby_version.rbx?
    return false if ruby_version.jruby?
    @threads.each(&:join)

    true
  end

  # Checks to see if 3 minor versions exist above current version
  #
  # for example 2.4.0 would check for existance of:
  #   - 2.5.0
  #   - 2.6.0
  #   - 2.7.0
  #   - 2.8.0
  private def check_eol_versions_minor(base_version = ruby_version)
    (1..4).each do |i|
      @threads << Thread.new do
        version = base_version.next_minor_version(i)
        next unless @fetcher.exists?("#{version}.tgz")

        @eol_versions << version
      end
    end
  end

  # Checks to see if one major version exists above current version
  # if it does, then it will check for minor versions of that version
  #
  # For checking 2.5. it would check for the existance of 3.0.0
  #
  # If 3.0.0 exists then it will check for:
  #   - 3.1.0
  #   - 3.2.0
  #   - 3.3.0
  private def check_eol_versions_major
    @threads << Thread.new do
      version = ruby_version.next_major_version(1)
      next unless @fetcher.exists?("#{version}.tgz")

      @eol_versions << version

      check_eol_versions_minor(RubyVersion.new(version), 1..3)
    end
  end

  # Checks for a range of "tiny" versions in parallel
  #
  # For example if 2.5.0 is given it will check for the existance of
  # - 2.5.1
  # - 2.5.2
  # - 2.5.3
  # - 2.5.4
  # - 2.5.5
  #
  # If the last elment in the series exists, it will continue to
  # search by enqueuing additional numbers until the final
  # value in the series is found
  private def check_minor_versions(range)
    range.each do |i|
      @threads << Thread.new do
        version = ruby_version.next_logical_version(i)
        next unless @fetcher.exists?("#{version}.tgz")
        @minor_versions[i] = version

        # If the last version exists, keep going until we find the end
        check_minor_versions(Range.new(i+1, i+i)) if i == range.last
      end
    end
  end
end
