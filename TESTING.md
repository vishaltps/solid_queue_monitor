# Testing Strategy for SolidQueueMonitor

This project uses a dual testing strategy:

1. **Rails-integrated tests** - Traditional tests that require the Rails environment
2. **Mock-based tests** - Faster tests that use mocks to simulate Rails components

## Mock-based Tests

Mock-based tests are designed to run independently of Rails using custom mock objects. These tests are:

- **Fast**: No Rails environment loading required
- **Isolated**: No database dependencies
- **Reliable**: Immune to Rails engine loading issues

### Running Mock Tests

To run only the mock-based tests:

```bash
./script/run_mock_tests.sh
```

Or manually:

```bash
bundle exec rspec --options .rspec.mock
```

## Rails-integrated Tests

Traditional Rails tests require the full Rails environment with database access. These tests:

- **More realistic**: Test actual integration with Rails
- **Slower**: Require loading the entire Rails environment
- **Database-dependent**: Require a properly set up test database

### Running Rails Tests

To run the Rails-integrated tests:

```bash
INCLUDE_RAILS_TESTS=true bundle exec rspec
```

## Test Types

### Mock System Tests

Mock system tests simulate browser interactions without loading Rails or Capybara:

```ruby
RSpec.describe 'Feature', type: :system do
  include MockSystemTest

  it 'does something' do
    visit '/path'
    expect(page.html).to include('Expected text')
  end
end
```

### Mock Controller Tests

Controller tests use mock controller classes:

```ruby
RSpec.describe 'Controller' do
  include MockRequest

  it 'handles a request' do
    response = get '/path'
    expect(response.status).to eq(200)
  end
end
```

### Mock Service Tests

Service tests directly test service objects:

```ruby
RSpec.describe ServiceClass do
  it 'performs its function' do
    result = described_class.method(args)
    expect(result).to eq(expected_value)
  end
end
```

## Adding New Tests

When adding new tests, consider whether they need Rails integration:

1. If they do **not** need Rails, use mocks and place them in the mock test suite
2. If they **do** need Rails, tag them with `:rails_required => true`

## Converting Existing Tests

To convert a Rails-dependent test to use mocks:

1. Replace `require 'rails_helper'` with `require 'spec_helper'`
2. Add appropriate mock modules (e.g., `include MockSystemTest`)
3. Replace Rails-specific assertions with mock-compatible ones
4. Test with `./script/run_mock_tests.sh` to ensure it works
