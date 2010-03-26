ActionController::Routing::Routes.draw do |map|
  map.connect 'wiki_external_filter/:filename', :controller => 'wiki_external_filter', :action => 'filter', :macro => 'flowplayer', :index => '1', :requirements => { :filename => /\S+\.flv/ }
end
