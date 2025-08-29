# frozen_string_literal: true

require "spec_helper"

RSpec.describe ApiCursorPagination::Concern do
  let(:test_class) do
    Class.new do
      include ApiCursorPagination::Concern
      
      def initialize
        @errors = []
      end
      
      attr_reader :errors
    end
  end
  
  let(:instance) { test_class.new }

  # Mock scope class for testing pagination
  let(:mock_scope) do
    Class.new do
      attr_accessor :records, :limited, :ordered_by, :having_clauses
      
      def initialize(records = [])
        @records = records
        @limited = nil
        @ordered_by = nil
        @having_clauses = []
      end
      
      def size
        @records.size
      end
      
      def limit(count)
        new_scope = self.class.new(@records)
        new_scope.limited = count
        new_scope.ordered_by = @ordered_by
        new_scope.having_clauses = @having_clauses.dup
        new_scope
      end
      
      def order(field)
        new_scope = self.class.new(@records)
        new_scope.limited = @limited
        new_scope.ordered_by = field
        new_scope.having_clauses = @having_clauses.dup
        new_scope
      end
      
      def having(condition, value)
        new_scope = self.class.new(@records)
        new_scope.limited = @limited
        new_scope.ordered_by = @ordered_by
        new_scope.having_clauses = @having_clauses.dup + [{ condition: condition, value: value }]
        new_scope
      end
      
      def to_a
        result = @records.dup
        
        # Apply having clauses
        @having_clauses.each do |clause|
          if clause[:condition].include?(">")
            result = result.select { |r| r.id > clause[:value].to_i }
          elsif clause[:condition].include?("<")
            result = result.select { |r| r.id < clause[:value].to_i }
          end
        end
        
        # Apply ordering
        if @ordered_by == "id desc"
          result = result.sort_by(&:id).reverse
        elsif @ordered_by == "id"
          result = result.sort_by(&:id)
        end
        
        # Apply limit
        result = result.take(@limited) if @limited
        
        result
      end
    end
  end
  
  # Mock record class
  let(:mock_record) do
    Struct.new(:id) do
      def send(method_name)
        if method_name.to_s == "id"
          id
        else
          super
        end
      end
    end
  end

  describe "#validate_and_setup_page_params" do
    context "when no page options are provided" do
      it "sets page_size to 0" do
        instance.validate_and_setup_page_params({})
        expect(instance.page_size).to eq(0)
      end
      
      it "does not add any errors" do
        instance.validate_and_setup_page_params({})
        expect(instance.errors).to be_empty
      end
    end

    context "when valid page size is provided" do
      let(:params) { { page: { size: "10" } } }
      
      it "sets the page_size correctly" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.page_size).to eq(10)
      end
      
      it "does not add any errors" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.errors).to be_empty
      end
    end

    context "when invalid page size is provided" do
      let(:params) { { page: { size: "0" } } }
      
      it "adds an error" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.errors).not_to be_empty
        expect(instance.errors.first[:title]).to eq("Invalid Parameter.")
        expect(instance.errors.first[:detail]).to include("page[size] is required and must be a positive integer")
      end
    end

    context "when sort parameter is provided" do
      let(:params) { { page: { size: "10", sort: "name" } } }
      
      it "adds an unsupported sort error" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.errors).not_to be_empty
        expect(instance.errors.first[:title]).to eq("Unsupported Sort.")
        expect(instance.errors.first[:detail]).to include("page[sort] is not supported")
      end
    end

    context "when both before and after are provided" do
      let(:params) { { page: { size: "10", before: "5", after: "1" } } }
      
      it "adds a range pagination error" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.errors).not_to be_empty
        expect(instance.errors.first[:title]).to eq("Range Pagination Not Supported.")
        expect(instance.errors.first[:detail]).to include("Range pagination not supported")
      end
    end

    context "when valid before parameter is provided" do
      let(:params) { { page: { size: "10", before: "5" } } }
      
      it "sets page_before correctly" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.page_before).to eq("5")
        expect(instance.errors).to be_empty
      end
    end

    context "when empty before parameter is provided" do
      let(:params) { { page: { size: "10", before: "" } } }
      
      it "adds an invalid parameter error" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.errors).not_to be_empty
        expect(instance.errors.first[:detail]).to eq("page[before] is invalid")
      end
    end

    context "when valid after parameter is provided" do
      let(:params) { { page: { size: "10", after: "5" } } }
      
      it "sets page_after correctly" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.page_after).to eq("5")
        expect(instance.errors).to be_empty
      end
    end

    context "when empty after parameter is provided" do
      let(:params) { { page: { size: "10", after: "" } } }
      
      it "adds an invalid parameter error" do
        instance.validate_and_setup_page_params(params[:page])
        expect(instance.errors).not_to be_empty
        expect(instance.errors.first[:detail]).to eq("page[after] is invalid")
      end
    end
  end

  describe "#paginate" do
    let(:records) do
      (1..10).map { |i| mock_record.new(i) }
    end
    
    let(:scope) { mock_scope.new(records) }

    context "when page_size is 0" do
      before { instance.page_size = 0 }
      
      it "returns all records without pagination" do
        result = instance.paginate(scope, "id")
        expect(result.size).to eq(10)
        expect(result.map(&:id)).to eq((1..10).to_a)
      end
    end

    context "when page_size is greater than 0" do
      before { instance.page_size = 3 }
      
      it "sets total_size correctly" do
        instance.paginate(scope, "id")
        expect(instance.total_size).to eq(10)
      end
      
      it "calculates total_pages correctly" do
        instance.paginate(scope, "id")
        expect(instance.total_pages).to eq(4) # 10 records / 3 per page = 4 pages
      end
      
      it "returns limited records" do
        result = instance.paginate(scope, "id")
        expect(result.size).to eq(3)
        expect(result.map(&:id)).to eq([1, 2, 3])
      end
      
      it "sets cursor IDs correctly" do
        result = instance.paginate(scope, "id")
        expect(instance.next_page_cursor_id).to eq(3)
        expect(instance.prev_page_cursor_id).to eq(1)
      end
    end

    context "when using page_after" do
      before do
        instance.page_size = 3
        instance.page_after = "3"
      end
      
      it "returns records after the cursor" do
        result = instance.paginate(scope, "id")
        expect(result.map(&:id)).to eq([4, 5, 6])
      end
    end

    context "when using page_before" do
      before do
        instance.page_size = 3
        instance.page_before = "8"
      end
      
      it "returns records before the cursor in correct order" do
        result = instance.paginate(scope, "id")
        expect(result.map(&:id)).to eq([5, 6, 7])
      end
    end
  end

  describe "#page_links_and_meta_data" do
    let(:base_url) { "https://api.example.com/users" }
    let(:query_params) { { filter: "active" } }

    context "when page_size is 0" do
      before { instance.page_size = 0 }
      
      it "returns empty hash" do
        result = instance.page_links_and_meta_data(base_url, query_params)
        expect(result).to eq({})
      end
    end

    context "when page_size is greater than 0" do
      before do
        instance.page_size = 10
        instance.total_size = 100
        instance.total_pages = 10
        instance.next_page_cursor_id = 20
        instance.prev_page_cursor_id = 10
      end
      
      it "returns meta information" do
        result = instance.page_links_and_meta_data(base_url, query_params)
        
        expect(result[:meta][:page][:total]).to eq(100)
        expect(result[:meta][:page][:pages]).to eq(10)
        expect(result[:meta][:page][:cursor][:before]).to eq(10)
        expect(result[:meta][:page][:cursor][:after]).to eq(20)
      end
      
      it "includes prev and next links" do
        result = instance.page_links_and_meta_data(base_url, query_params)
        
        expect(result[:links][:prev]).to include("page%5Bbefore%5D=10")
        expect(result[:links][:prev]).to include("page%5Bsize%5D=10")
        expect(result[:links][:prev]).to include("filter=active")
        
        expect(result[:links][:next]).to include("page%5Bafter%5D=20")
        expect(result[:links][:next]).to include("page%5Bsize%5D=10")
        expect(result[:links][:next]).to include("filter=active")
      end
    end

    context "when only next_page_cursor_id is present" do
      before do
        instance.page_size = 10
        instance.total_size = 100
        instance.total_pages = 10
        instance.next_page_cursor_id = 20
        instance.prev_page_cursor_id = nil
      end
      
      it "only includes next link" do
        result = instance.page_links_and_meta_data(base_url, query_params)
        
        expect(result[:links]).to have_key(:next)
        expect(result[:links]).not_to have_key(:prev)
        expect(result[:meta][:page][:cursor]).not_to have_key(:before)
        expect(result[:meta][:page][:cursor][:after]).to eq(20)
      end
    end

    context "when only prev_page_cursor_id is present" do
      before do
        instance.page_size = 10
        instance.total_size = 100
        instance.total_pages = 10
        instance.next_page_cursor_id = nil
        instance.prev_page_cursor_id = 10
      end
      
      it "only includes prev link" do
        result = instance.page_links_and_meta_data(base_url, query_params)
        
        expect(result[:links]).to have_key(:prev)
        expect(result[:links]).not_to have_key(:next)
        expect(result[:meta][:page][:cursor][:before]).to eq(10)
        expect(result[:meta][:page][:cursor]).not_to have_key(:after)
      end
    end
  end
end
