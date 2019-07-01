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
    # @minor_versions = 10.times.each_with_object({}) { |i,h| h[ruby_version.next_logical_version(i + 1)] = i + 1 }
    @threads = []
  end

  def suggested_ruby_minor_version
    return ruby_version unless can_check?

    @threads.each(&:join)

    suggested_version = @ruby_version
    @minor_versions.detect do |version|
      suggested_version = version  if version
      !version # keep going until we find a falsey version
    end

    suggested_version
  end

  def call
    return unless can_check?

    check_minor_versions(1..5)
    self
  end

  def can_check?
    return false if ruby_version.patchlevel_is_significant?
    return false if ruby_version.rbx?
    return false if ruby_version.jruby?
    true
  end

  def check_minor_versions(range)
    range.each do |i|
      @threads << Thread.new do
        version = ruby_version.next_logical_version(i)
        @minor_versions[i] = version if @fetcher.exists?("#{version}.tgz")

        # If the last version exists, keep going until we find the end
        next if i != range.last
        next if !@minor_versions[i]

        # Recursion
        check_minor_versions(Range.new(i+1, i+i))
      end
    end
  end
end
