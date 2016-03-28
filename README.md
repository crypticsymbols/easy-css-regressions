# EasyCssRegressions

This gem is intended to make CSS regression testing with Capybara and Poltergiest as easy as possible.

## Usage

It provides the Capybara DSL addition `element_regression?('#selector')`, which will compare the baseline screenshot of that css selector (based on either current_url or a specific key) which is checked into your version control, to a screenshot taken during the test. If the images are different (using imagemagick's `compare` command), the spec will fail.

To start using, install the gem, configure to your desire, and add `element_regression?('#css-selector div.whatever')` to a spec. When no image exists, it will take a reference shot and store it in `spec/support/regressions/` so you can check it in. Comparisons and diffs are stored in `tmp/regressions`. If you have Launchy installed, it will open failed diffs automatically.

To regenerate the image and use the new, different rendering as the correct version, rerun the spec one time with `reset: true`, like this: `element_regression?('#selector', reset: true)`. Remove `reset: true` (otherwise it will regenerate every run and never fail), check in that image, and it's the new reference image for future changes.

### DSL

- `element_regression?('#selector')`: check the matching selector on the current page against the existing reference image.
- `element_regression?('#selector', key: 'your-desciptive-key')`: instead of using the page URL as the storage key, use your own string. Storage keys get chopped up and converted to directory paths that roughly translate to URLs, in case you want to track down a reference image on your own. This also means it's easier to track regressions for the same selector in different contexts.
- `element_regression?('#selector', refresh: true)`: You're confirmed that the change that failed the spec is intentional and you want to save the new version as the baseline. Don't forget to check the updated image into version control and *REMOVE THIS FLAG*. Otherwise it will refresh on every run and the spec will never fail.

## Todo

- See if there's a way to support other drivers like selenium and chromedriver. As far as I can tell, only poltergeist supports element-level screenshots, and it's much easier to ensure mock text and images don't change from spec to spec when you're not talking about the entire page.
- Provide a setting to override specific images or text by selector to a default value. Random lipsum will fail specs, because it's visually different.

## Setup

In your rspec config:
```
# require the gem
require 'easy_css_regressions'

# Optional configuration
CssRegressionTest.default_key_mode = [:fragment]
CssRegressionTest.base_asset_path = ''
CssRegressionTest.temp_asset_path = ['tmp', 'path']
CssRegressionTest.durable_asset_path = ['tmp', 'durable', 'path']

# Include for feature specs
RSpec.configure do |config|
  config.include EasyCssRegressions, type: :feature
end
```

## Configuration options

- `CssRegressionTest.default_key_mode`: Set the default format for key generation to store screenshots based on URL path. Pass an array of symbols (e.g. `[:path, :query]`) that match method names used to extract info from `URI.parse(current_url)`. The default is `[:path, :query, :fragment]`, but for an angular app with `/#/urls`, you may really only want `[:fragment]`, which is the hash portion.
- `CssRegressionTest.base_asset_path`: Base path for asset storage. Defaults to '' (blank string) but you might end up wanting to expliticly set it to `Rails.root` or similar. IDK, YMMV.
- `CssRegressionTest.temp_asset_path`: Where the comparison and diff images will be stored. Defaults to `tmp/regressions`, and is based on the `base_asset_path`. Set with array that will be passed to `File.join`, like `['tmp', 'regressions']`.
- `CssRegressionTest.durable_asset_path`: Where the reference images, e.g. the 'correct' renderings of element, are stored. This should probably be in version control, so it defaults to `['spec', 'support', 'regressions']`.

## Pull requests

Awesome! Yes. Write specs. Thanks!

## Support

If you're having issues, I'd love to help and improve this gem. But please remember I'm just one guy and I'm usually busy or sleepy. Occasionally, I'm just apathetic. There really isn't much code here, so try to dig a little bit first.
