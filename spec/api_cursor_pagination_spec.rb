# frozen_string_literal: true

require "spec_helper"

RSpec.describe ApiCursorPagination do
  it "has a version number" do
    expect(ApiCursorPagination::VERSION).not_to be_nil
  end

  it "can be required without error" do
    expect { require "api_cursor_pagination" }.not_to raise_error
  end

  describe "module structure" do
    it "defines the main module" do
      expect(defined?(ApiCursorPagination)).to eq("constant")
    end

    it "defines the concern module" do
      expect(defined?(ApiCursorPagination::Concern)).to eq("constant")
    end

    it "defines the version" do
      expect(defined?(ApiCursorPagination::VERSION)).to eq("constant")
    end
  end

  describe "Error class" do
    it "defines a custom error class" do
      expect(ApiCursorPagination::Error).to be < StandardError
    end
  end
end
