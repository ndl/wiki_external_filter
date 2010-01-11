require 'digest/sha2'

module WikiExternalFilterHelper

  def load_config
    unless @config
      config_file = "#{RAILS_ROOT}/config/wiki_external_filter.yml"
      unless File.exists?(config_file)
        raise "Config not found: #{config_file}"
      end
      @config = YAML.load_file(config_file)[RAILS_ENV]
    end
    @config
  end

  def has_macro(macro)
    config = load_config
    config.key?(macro)
  end

  module_function :load_config, :has_macro

  def construct_cache_key(macro, name)
    ['wiki_external_filter', macro, name].join("/")
  end

  def build(text, macro, info)

    name = Digest::SHA256.hexdigest(text)
    result = {}
    content = nil
    cache_key = nil
    expires = 0

    if info.key?('cache_seconds')
      expires = info['cache_seconds']
    else
      expires = Setting.plugin_wiki_external_filter['cache_seconds'].to_i
    end

    if expires > 0
      cache_key = self.construct_cache_key(macro, name)
      content = read_fragment cache_key, :expires_in => expires.seconds
    end

    if content
      result[:source] = text
      result[:content] = content
      result[:content_type] = info['content_type']
      RAILS_DEFAULT_LOGGER.debug "from cache: #{name}"
    else
      result = self.build_forced(text, info)
      if result[:status]
        if expires > 0
          write_fragment cache_key, result[:content], :expires_in => expires.seconds
	  RAILS_DEFAULT_LOGGER.debug "cache saved: #{name}"
	end
      else
        raise "Error applying external filter: #{result[:content]}"
      end
    end

    result[:name] = name
    result[:macro] = macro

    return result
  end

  def build_forced(text, info)

    result = {}

    RAILS_DEFAULT_LOGGER.debug "executing command: #{info['command']}"

    content = IO.popen(info['command'], 'r+b') { |f|
      f.write info[:prolog] if info.key?(:prolog)
      f.write CGI.unescapeHTML(text)
      f.write info[:epilog] if info.key?(:epilog)
      f.close_write
      f.read
    }

    RAILS_DEFAULT_LOGGER.info("child status: sig=#{$?.termsig}, exit=#{$?.exitstatus}")

    result[:content] = content
    result[:content_type] = info['content_type']
    result[:source] = text
    result[:status] = $?.exitstatus == 0

    return result
  end

  def render_tag(result)
    render_to_string :template => 'wiki_external_filter/macro_inline', :layout => false, :locals => result
  end

  def render_block(result, wiki_name)
    result = result.dup
    result[:wiki_name] = wiki_name
    render_to_string :template => 'wiki_external_filter/macro_block', :layout => false, :locals => result
  end

  class Macro
    def initialize(view, source, macro, info)
      @view = view
      @view.controller.extend(WikiExternalFilterHelper)
      source.gsub!(/<br \/>/, "")
      source.gsub!(/<\/?p>/, "")
      @result = @view.controller.build(source, macro, info)
    end

    def render()
      @view.controller.render_tag(@result)
    end

    def render_block(wiki_name)
      @view.controller.render_block(@result, wiki_name)
    end
  end
end
