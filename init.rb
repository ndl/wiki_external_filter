require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting wiki_external_filter plugin for Redmine'

Redmine::Plugin.register :wiki_external_filter do
  name 'Wiki External Filter Plugin'
  author 'Alexander Tsvyashchenko'
  description 'Processes given text using external command and renders its output'
  author_url 'http://www.ndl.kiev.ua'
  version '0.0.2'
  settings :default => {'cache_seconds' => '0'}, :partial => 'wiki_external_filter/settings'

  config = WikiExternalFilterHelper.load_config
  RAILS_DEFAULT_LOGGER.debug "Config: #{config.inspect}"

  config.keys.each do |name|
    RAILS_DEFAULT_LOGGER.info "Registering #{name} macro with wiki_external_filter"
    Redmine::WikiFormatting::Macros.register do
      info = config[name]
      desc info['description']
      macro name do |obj, args|
        m = WikiExternalFilterHelper::Macro.new(self, args.to_s, obj.respond_to?('page') ? obj.page.attachments : nil, name, info)
	m.render
      end

      # code borrowed from wiki latex plugin
      # code borrowed from wiki template macro
      desc info['description']
      macro (name + "_include").to_sym do |obj, args|
        page = Wiki.find_page(args.to_s, :project => @project)
        raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)

        @included_wiki_pages ||= []
        raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
        @included_wiki_pages << page.title
        m = WikiExternalFilterHelper::Macro.new(self, page.content.text, page.attachments, name, info)
        @included_wiki_pages.pop
        m.render_block(args.to_s)
      end
    end
  end

end
