require 'digest/sha2'
require 'open4'

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

  def build(text, attachments, macro, info)

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
      result = self.build_forced(text, attachments, info)
      if result[:status]
        if expires > 0
          write_fragment cache_key, result[:content], :expires_in => expires.seconds
	  RAILS_DEFAULT_LOGGER.debug "cache saved: #{name}"
	end
      else
        raise "Error applying external filter: stdout is #{result[:content]}, stderr is #{result[:errors]}"
      end
    end

    result[:name] = name
    result[:macro] = macro

    return result
  end

  def build_forced(text, attachments, info)

    if info['replace_attachments'] and attachments
      attachments.each do |att|
        text.gsub!(/#{att.filename.downcase}/i, att.diskfile)
      end
    end

    result = {}
    content = []
    errors = ""

    commands = info['commands']? info['commands'] : [info['command']]

    commands.each do |command|
      RAILS_DEFAULT_LOGGER.info "executing command: #{command}"

      c = nil
      e = nil

      Open4::popen4(command) { |pid, fin, fout, ferr|
        fin.write info[:prolog] if info.key?(:prolog)
        fin.write CGI.unescapeHTML(text)
        fin.write info[:epilog] if info.key?(:epilog)
        fin.close
        c, e = [fout.read, ferr.read]
      }

      RAILS_DEFAULT_LOGGER.debug("child status: sig=#{$?.termsig}, exit=#{$?.exitstatus}")

      content << c
      errors += e if e
    end

    result[:content] = content
    result[:errors] = errors
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
    def initialize(view, source, attachments, macro, info)
      @view = view
      @view.controller.extend(WikiExternalFilterHelper)
      source.gsub!(/<br \/>/, "")
      source.gsub!(/<\/?p>/, "")
      @result = @view.controller.build(source, attachments, macro, info)
    end

    def render()
      @view.controller.render_tag(@result)
    end

    def render_block(wiki_name)
      @view.controller.render_block(@result, wiki_name)
    end
  end
end
