require "spec_helper"

describe LanguagePack::Helpers::OutdatedRubyVersion do
  let(:stack) { "heroku-16" }
  let(:fetcher) { LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, stack) }

  it "finds the latest version on a stack" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.2.5")
    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call
    expect(outdated.suggested_ruby_minor_version).to eq("ruby-2.2.10")
    expect(outdated.eol?).to eq(true)
    expect(outdated.maybe_eol?).to eq(true)
  end

  it "detects returns original ruby version when using the latest" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-2.2.10")
    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call
    expect(outdated.suggested_ruby_minor_version).to eq(ruby_version)
  end

  it "Doesn't do anything when using a patch significant version" do
    ruby_version = LanguagePack::RubyVersion.new("ruby-1.9.3p123")
    outdated = LanguagePack::Helpers::OutdatedRubyVersion.new(
      ruby_version: ruby_version,
      fetcher: fetcher
    )

    outdated.call
    expect(outdated.suggested_ruby_minor_version).to eq(ruby_version)
    expect(outdated.can_check?).to eq(false)
  end
end
