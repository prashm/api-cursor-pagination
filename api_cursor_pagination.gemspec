# frozen_string_literal: true

require_relative "lib/api_cursor_pagination/version"

Gem::Specification.new do |spec|
  spec.name = "api_cursor_pagination"
  spec.version = ApiCursorPagination::VERSION
  spec.authors = ["Prashant Mokkarala"]
  spec.email = ["prashm@gmail.com"]

  spec.summary = "A Rails concern for implementing cursor-based pagination in APIs"
  spec.description = "ApiCursorPagination provides a Rails concern that implements cursor-based pagination following the JSON:API cursor pagination profile. It allows for efficient pagination of large datasets by using cursor-based navigation instead of offset-based pagination."
  spec.homepage = "https://github.com/prashm/api_cursor_pagination"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/prashm/api_cursor_pagination"
  spec.metadata["changelog_uri"] = "https://github.com/prashm/api_cursor_pagination/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "activesupport", ">= 5.0"
  spec.add_dependency "railties", ">= 5.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rails", ">= 5.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rails", "~> 2.0"
  spec.add_development_dependency "rubocop-rspec", "~> 2.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
