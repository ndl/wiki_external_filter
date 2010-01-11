
class WikiExternalFilterController < ApplicationController

  include WikiExternalFilterHelper

  def filter
    name = params[:name]
    macro = params[:macro]
    config = load_config
    cache_key = self.construct_cache_key(macro, name)
    content = read_fragment cache_key

    if (content)
      send_data content, :type => config[macro]['content_type'], :disposition => 'inline'
    else
      render_404
    end
  end
end
