# ApiCursorPagination

[![Gem Version](https://badge.fury.io/rb/api_cursor_pagination.svg)](https://badge.fury.io/rb/api_cursor_pagination)

A Rails concern that implements cursor-based pagination for APIs, following the [JSON:API cursor pagination profile](https://jsonapi.org/profiles/ethanresnick/cursor-pagination/).

## Features

- 🚀 **Efficient Pagination**: Cursor-based pagination for large datasets
- 📊 **JSON:API Compliant**: Follows the JSON:API cursor pagination specification
- 🔧 **Easy Integration**: Simple Rails concern that can be included in any controller
- 🎯 **Flexible**: Supports custom cursor fields and query scopes
- ✅ **Well Tested**: Comprehensive test suite included
- 🛡️ **Error Handling**: Built-in validation and error responses

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'api_cursor_pagination'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install api_cursor_pagination
```

Or simply include the concern file (lib/api_cursor_pagination/concern.rb) in your app/controllers/concerns folder.


## Requirements

- Ruby >= 2.5.0
- Rails >= 5.0
- ActiveSupport >= 5.0

## Usage

### Basic Setup

Include the concern in your API controller:

```ruby
class UsersController < ApplicationController
  include ApiCursorPagination::Concern

  def index
    # Initialize errors array
    @errors = []
    
    # Validate and set pagination options from params
    validate_and_setup_page_params(params[:page])

    if @errors.blank?
      # Build your query scope
      scope = User.active.includes(:profile).select('users.*, profiles.*, users.id user_id')
      
      # Get paginated results
      users = paginate(scope, 'users_id')

      # Build API response with pagination metadata
      response = {
        status: 'Success',
        data: users.map(&:as_json)
      }.merge(page_links_and_meta_data(request.base_url + request.path, request.query_parameters))

      render json: response, status: :ok
    else
      render json: error_response, status: :bad_request
    end
  end

  private

  def error_response
    {
      status: 'Error',
      errors: @errors.map { |error| error.is_a?(Hash) ? error : { title: error } }
    }
  end
end
```

### API Usage

#### Request Format

Pagination parameters should be passed in the `page` parameter:

```
GET /api/users?page[size]=10
GET /api/users?page[size]=10&page[after]=123
GET /api/users?page[size]=10&page[before]=456
```

#### Parameters

- `page[size]` (required): Number of records per page (must be positive integer)
- `page[after]` (optional): Cursor to get records after this ID
- `page[before]` (optional): Cursor to get records before this ID
- `page[sort]` (not supported): Will return an error if provided

**Note**: You cannot use both `page[before]` and `page[after]` in the same request.

#### Response Format

```json
{
  "status": "Success",
  "data": [...],
  "meta": {
    "page": {
      "cursor": {
        "before": 123,
        "after": 456
      },
      "total": 1000,
      "pages": 100
    }
  },
  "links": {
    "prev": "https://api.example.com/users?page[before]=123&page[size]=10",
    "next": "https://api.example.com/users?page[after]=456&page[size]=10"
  }
}
```

### Advanced Usage

#### Custom Cursor Fields

You can use different fields for the SQL query scope and the returned row IDs:

```ruby
# If your query uses a complex cursor but rows have simple IDs
scope = User.joins(:orders).select('users.*, CAST(CONCAT(users.id, ".", IFNULL(orders.id, 0)) AS DECIMAL(40,20)) as cursor_id')
users = paginate(scope, 'cursor_id')
```

#### Complex Queries

The concern works with any ActiveRecord scope:

```ruby
def index
  validate_and_setup_page_params(params[:page])
  
  if @errors.blank?
    scope = User.joins(:orders)
                .where(orders: { status: 'active' })
                .group('users.id')
                .select('users.*, MAX(orders.created_at) as last_order_date')
                
    users = paginate(scope, 'last_order_date')
    
    # ... render response
  end
end
```

## API Reference

### Methods

#### `validate_and_setup_page_params(params)`

Validates pagination parameters and sets instance variables.

**Parameters:**
- `params` - The request parameters hash

**Sets:**
- `@page_size` - Number of records per page
- `@page_before` - Cursor for pagination before this ID
- `@page_after` - Cursor for pagination after this ID
- `@errors` - Array of validation errors

#### `paginate(scope, scope_id_str, row_id_str = scope_id_str)`

Returns paginated results from the given scope.

**Parameters:**
- `scope` - ActiveRecord scope/relation
- `scope_id_str` - Field name used in SQL queries for cursor comparison
- `row_id_str` - Field name on returned objects for cursor values (defaults to scope_id_str)

**Returns:** Array of records

**Sets:**
- `@total_size` - Total number of records in scope
- `@total_pages` - Total number of pages
- `@next_page_cursor_id` - Cursor ID for next page
- `@prev_page_cursor_id` - Cursor ID for previous page

#### `page_links_and_meta_data(base_url, query_params)`

Generates pagination metadata and links.

**Parameters:**
- `base_url` - Base URL for pagination links
- `query_params` - Current query parameters

**Returns:** Hash with `meta` and `links` keys

## Error Handling

The gem provides detailed error responses for various scenarios:

### Invalid Page Size
```json
{
  "title": "Invalid Parameter.",
  "detail": "page[size] is required and must be a positive integer; got 0",
  "source": { "parameter": "page[size]" }
}
```

### Unsupported Sort
```json
{
  "title": "Unsupported Sort.",
  "detail": "page[sort] is not supported; got page[sort]=name",
  "source": { "parameter": "page[sort]" },
  "links": { "type": ["https://jsonapi.org/profiles/ethanresnick/cursor-pagination/unsupported-sort"] }
}
```

### Range Pagination Not Supported
```json
{
  "title": "Range Pagination Not Supported.",
  "detail": "Range pagination not supported; got page[before]=123 and page[after]=456",
  "links": { "type": ["https://jsonapi.org/profiles/ethanresnick/cursor-pagination/range-pagination-not-supported"] }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running Tests

```bash
# Run all tests
bundle exec rake spec

# Run with coverage
bundle exec rspec

# Run linting
bundle exec rubocop
```

### Code Quality

This gem follows Ruby best practices and includes:

- RuboCop for code style enforcement
- RSpec for comprehensive testing
- Semantic versioning
- Changelog maintenance

## Performance Considerations

Cursor-based pagination is generally more efficient than offset-based pagination, especially for large datasets. However, keep these points in mind:

1. **Database Indexes**: Ensure your cursor field is properly indexed
2. **Query Complexity**: Complex joins may impact performance
3. **Total Count**: The `total_size` calculation runs a separate COUNT query
4. **Memory Usage**: Large page sizes will use more memory

## Comparison with Offset Pagination

| Feature | Cursor Pagination | Offset Pagination |
|---------|------------------|-------------------|
| Performance on large datasets | ✅ Excellent | ❌ Degrades |
| Consistent results during data changes | ✅ Yes | ❌ No |
| Jump to arbitrary page | ❌ No | ✅ Yes |
| Bi-directional navigation | ✅ Yes | ✅ Yes |
| Implementation complexity | 🟡 Medium | ✅ Simple |

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/prashm/api_cursor_pagination. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/prashm/api_cursor_pagination/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ApiCursorPagination project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/prashm/api_cursor_pagination/blob/main/CODE_OF_CONDUCT.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

## Support

If you have any questions or issues, please:

1. Check the [documentation](https://github.com/prashm/api_cursor_pagination)
2. Search [existing issues](https://github.com/prashm/api_cursor_pagination/issues)
3. Create a [new issue](https://github.com/prashm/api_cursor_pagination/issues/new) if needed

## Acknowledgments

- Based on the [JSON:API cursor pagination profile](https://jsonapi.org/profiles/ethanresnick/cursor-pagination/)
- Inspired by best practices from various pagination implementations
