require 'spec_helper'

describe CssRegressionTest do

  before { allow_any_instance_of(described_class).to receive(:timestamp).and_return 999 }
  before { allow(Capybara).to receive(:javascript_driver).and_return :poltergeist }

  describe 'class level settings' do
    subject { described_class.new('#selector') }
    before {
      allow_any_instance_of(described_class).to receive(:get_page_url).and_return URI.parse('http://example.com/foo/bar?baz=derp#/hash/url?fragment/')
      described_class.default_key_mode = [:fragment]
      described_class.base_asset_path = '/derp/'
      described_class.temp_asset_path = ['tmp', 'path']
      described_class.durable_asset_path = ['durable', 'path']
    }
    after {
      described_class.default_key_mode = [:path, :query, :fragment]
      described_class.base_asset_path = ''
      described_class.temp_asset_path = ['tmp', 'regressions']
      described_class.durable_asset_path = ['spec', 'support', 'regressions']
    }
    it 'does the thing' do
      expect(subject.key).to eq(['hash','url','fragment'])
      expect(subject.send(:base_image_path)).to eq('/derp/durable/path/hash/url/fragment/selector.png')
      expect(subject.send(:diff_image_path)).to eq('/derp/tmp/path/hash/url/fragment/selector.diff.999.png')
      expect(subject.send(:compare_image_path)).to eq('/derp/tmp/path/hash/url/fragment/selector.compare.999.png')
    end
  end

  describe '#reset' do
    it 'resets the test when asked' do
      expect_any_instance_of(described_class).to receive(:`).with(/rm /)
      described_class.new('#selector', key: 'key', reset: true)
    end
    it 'does not reset when reset = false' do
      expect_any_instance_of(described_class).not_to receive(:`).with(/rm /)
      described_class.new('#selector', key: 'key')
    end
    it 'does not reset by default' do
      expect_any_instance_of(described_class).not_to receive(:`).with(/rm /)
      described_class.new('#selector', key: 'key')
    end
  end

  describe '#ensure_image_saved' do
    subject { described_class.new('#selector', key: 'key') }
    let(:base_path) { subject.send(:base_image_path) }
    let(:compare_path) { subject.send(:compare_image_path) }
    context 'image does not exist' do
      before { expect(File).to receive(:exists?).with(base_path).and_return(false) }
      before { expect(subject).to receive(:save_screenshot).with(base_path, selector: subject.selector).and_return(base_path) }
      it 'creates the image and returns the path' do
        subject.send(:ensure_image_saved, base_path)
      end
    end
    context 'image exists' do
      before { expect(File).to receive(:exists?).with(base_path).and_return(true) }
      it 'creates the image and returns the path' do
        subject.send(:ensure_image_saved, base_path)
      end
    end
  end

  describe 'selector is preserved' do
    subject { described_class.new('#selector .hello-world span', key: 'derp-derp') }
    it 'preserves the selector' do |variable|
      expect(subject.selector).to eq('#selector .hello-world span')
    end
  end

  describe 'uses URL to format default key' do
    subject { described_class.new('#selector') }
    before { allow_any_instance_of(described_class).to receive(:get_page_url).and_return URI.parse('http://example.com/foo/bar?baz=derp#/hash/url?fragment/') }
    it 'correctly format the key' do |variable|
      expect(subject.key).to eq(['foo','bar','baz=derp','hash','url','fragment'])
    end
  end

  it 'raises error if not using poltergeist' do
    allow(Capybara).to receive(:javascript_driver).and_return :selenium
    expect{described_class.new('r', key: 'r')}.to raise_error(Capybara::NotSupportedByDriverError)
  end

  it 'has a version number' do
    expect(EasyCssRegressions::VERSION).not_to be nil
  end

  it 'formats the key array correctly' do
    t = described_class.new('#selector', key: 'key-here/-is/okay?yeah=derp&foo=bar')
    expect(t.key).to eq(['key','here','is','okay','yeah=derp&foo=bar'])
  end

  describe 'diffing images' do
    subject { described_class.new('#selector', key: 'foo/bar') }
    context 'diff fails' do |variable|
      before { expect(subject).to receive(:`).and_return(`(exit 7)`) }
      it 'calls x' do
        expect(subject).to receive(:open_file)
        expect(subject.send(:compare_images)).to be false
      end
    end
    context 'diff succeeds' do |variable|
      before { expect(subject).to receive(:`).and_return(`(exit 0)`) }
      it 'calls x' do
        expect(subject.send(:compare_images)).to be true
      end
    end
    context '"compare" command not available' do |variable|
      before { expect(subject).to receive(:`).and_return(`exit 127`) }
      it 'calls x' do
        expect(subject.send(:compare_images)).to be nil
      end
    end
    context 'calls compare with correct args' do |variable|
      let(:string) { "compare -metric AE #{subject.send(:base_image_path)} #{subject.send(:compare_image_path)} #{subject.send(:diff_image_path)}" }
      before { expect(subject).to receive(:`).with(string).and_return(`(exit 0)`) }
      it 'calls x' do
        subject.send(:compare_images)
      end
    end
  end

  describe 'image paths' do
    subject { described_class.new('#selector', key: 'foo/bar') }
    it 'returns correct base image path' do
      expect(subject.send(:base_image_path)).to eq('spec/support/regressions/foo/bar/selector.png')
    end
    it 'returns correct diff image path' do
      expect(subject.send(:diff_image_path)).to eq('tmp/regressions/foo/bar/selector.diff.999.png')
    end

    it 'returns correct diff image path' do
      expect(subject.send(:compare_image_path)).to eq('tmp/regressions/foo/bar/selector.compare.999.png')
    end
  end

  describe 'wackier image paths' do
    subject { described_class.new('#selector .hello span', key: 'foo/-bar') }
    it 'returns correct base image path' do
      expect(subject.send(:base_image_path)).to eq('spec/support/regressions/foo/bar/selector-hello-span.png')
    end
    it 'returns correct diff image path' do
      expect(subject.send(:diff_image_path)).to eq('tmp/regressions/foo/bar/selector-hello-span.diff.999.png')
    end

    it 'returns correct diff image path' do
      expect(subject.send(:compare_image_path)).to eq('tmp/regressions/foo/bar/selector-hello-span.compare.999.png')
    end
  end

end
