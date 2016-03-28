class CssRegressionTest

  require 'capybara'
  include Capybara::DSL

  class << self
    attr_accessor :default_key_mode
    attr_accessor :durable_asset_path
    attr_accessor :temp_asset_path
    attr_accessor :base_asset_path
  end
  self.default_key_mode = [:path, :query, :fragment]
  self.durable_asset_path = ['spec', 'support', 'regressions']
  self.temp_asset_path = ['tmp', 'regressions']
  self.base_asset_path = ''

  attr_accessor :selector
  attr_accessor :key
  attr_accessor :timestamp

  def initialize(selector, **opts)
    if Capybara.javascript_driver != :poltergeist
      raise Capybara::NotSupportedByDriverError 
    end
    self.selector = selector.to_s
    opts[:key] ||= generate_key_from_path
    self.key = format_key(opts[:key])
    self.timestamp = Time.now.to_i
    # Setup complete
    reset if opts[:reset]
  end

  def run
    ensure_image_saved(base_image_path)
    ensure_image_saved(compare_image_path)
    compare_images
  end

  private

  def reset
    `rm #{base_image_path}`
  end

  def get_page_url
    URI.parse(current_url)
  end

  def generate_key_from_path
    url = get_page_url
    string = ''
    default_key_mode.each do |method|
      string = string + url.send(method).to_s+'/'
    end
    string
  end

  def default_key_mode
    self.class.default_key_mode
  end

  def temp_asset_path
    self.class.temp_asset_path
  end

  def durable_asset_path
    self.class.durable_asset_path
  end

  def base_asset_path
    self.class.base_asset_path
  end

  def format_key(string)
    string.to_s.split(/\/|\?|-/).reject{ |e| e.empty? }
  end

  def parameterize(string, sep = '-')
    # Turn unwanted chars into the separator
    new_string = string.gsub(/[^a-z0-9\-_]+/, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      new_string.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      new_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
    end
    new_string.downcase
  end

  def storage_dir(type=:tmp)
    path_array = (type == :tmp ? temp_asset_path : durable_asset_path)
    base_asset_path+File.join(path_array + self.key)+'/'
  end

  def base_image_path
    storage_dir(:spec)+img_filename()
  end

  def compare_image_path
    storage_dir(:tmp)+img_filename(:compare)
  end

  def diff_image_path
    storage_dir(:tmp)+img_filename(:diff)
  end

  def img_filename(type=:base)
    "#{parameterize(selector)}"+(type != :base ? ".#{type}.#{timestamp}" : nil).to_s+'.png'
  end

  def compare_images
    `compare -metric AE #{base_image_path} #{compare_image_path} #{diff_image_path}`
    status = $?.exitstatus.to_i
    if status == 127
      warn '"compare" command not found! Make sure imagemagick is installed and in your $PATH.'
      nil
    elsif (status != 0)
      open_file(diff_image_path)
      false
    else
      true
    end
  end

  def open_file(path)
    begin
      require "launchy"
      Launchy.open(path)
    rescue LoadError
      warn "File saved to #{path}."
      warn "Please install the launchy gem to open the file automatically."
    end
  end

  def ensure_image_saved(file_path)
    if File.exists?(file_path)
      file_path
    else
      save_screenshot(file_path, selector: selector)
    end
  end

end
