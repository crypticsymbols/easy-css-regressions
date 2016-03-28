require "easy_css_regressions/version"

module EasyCssRegressions
  
  require "capybara"
  require "capybara/dsl"

  require "easy_css_regressions/css_regression_test"
  
  def element_regression?(selector, **opts)
    test = CssRegressionTest.new(selector, opts)
    # isolate rspec from the test class itself
    # but also fail if the selector isn't there
    # because it makes more sense to use RSpec 
    # for that.
    expect(page).to have_selector(test.selector, count: 1)
    # return true if image matches,
    # nil if imagemagick isn't installed,
    # false if element changed.
    expect(test.run).not_to be(false)
  end
  
end
