require 'spec_helper'

feature 'it works' do

  before { allow(Launchy).to receive(:open).and_return nil }
  CssRegressionTest.base_asset_path = '/tmp/css-regressions/'
  after { `rm -Rf /tmp/rspec/` }


  scenario 'selector is missing' do
    visit '/has-bizarro-selector.html'
    expect{
      element_regression?('#selector', key: 'sdaf/asdf')
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, 'expected to find css "#selector" 1 time but there were no matches')
  end

  scenario 'regression test fails' do |variable|
    allow_any_instance_of(CssRegressionTest).to receive(:run).and_return(false)
    visit('/has-selector.html')
    expect{
      element_regression?('#selector', key: 'sdaf/asdf')
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  scenario 'regression test passes' do
    allow_any_instance_of(CssRegressionTest).to receive(:run).and_return(true)
    visit('/has-selector.html')
    expect{
      element_regression?('#selector', key: 'sdaf/asdf')
      }.not_to raise_error
  end

  scenario 'convert command not available' do
    allow_any_instance_of(CssRegressionTest).to receive(:`).and_return(`(exit 127)`)
    allow_any_instance_of(CssRegressionTest).to receive(:ensure_image_saved).and_return(true)
    visit('/has-selector.html')
    expect { 
      element_regression?('#selector', key: 'sdaf/asdf')
     }.to output(/command not found/).to_stderr
  end

  scenario 'all together (YOLO)' do
    # initial run
    visit('/has-selector.html')
    sleep 1
    element_regression?('#selector', key: 'sdaf/asdf')
    # no change
    visit('/has-selector.html')
    sleep 1
    element_regression?('#selector', key: 'sdaf/asdf')
    # change & fail
    js = "document.getElementById('selector').className = 'mutated'"
    page.evaluate_script(js)
    sleep 1
    expect{
      element_regression?('#selector', key: 'sdaf/asdf')
    }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    # reset
    element_regression?('#selector', key: 'sdaf/asdf', reset: true)
    # no fail.
    element_regression?('#selector', key: 'sdaf/asdf')
    # but when you come back to the page it will fail because the class was changed with JS, the baseline image is now different.
    visit('/has-selector.html')
    sleep 1
    expect{
      element_regression?('#selector', key: 'sdaf/asdf')
    }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    # and this page fails because it doesn't have the selector.
    visit('/has-bizarro-selector.html')
    sleep 1
    expect{
      element_regression?('#selector', key: 'sdaf/asdf')
    }.to raise_error(RSpec::Expectations::ExpectationNotMetError, 'expected to find css "#selector" 1 time but there were no matches')
  end

end
