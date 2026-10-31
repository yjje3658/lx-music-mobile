Pod::Spec.new do |s|
  s.name         = 'CarPlayBridge'
  s.version      = '0.1.0'
  s.summary      = 'CarPlay support for lx-music-mobile'
  s.homepage     = 'https://github.com/lyswhut/lx-music-mobile'
  s.license      = { :type => 'Apache-2.0' }
  s.author       = { 'lx-music-custom' => 'dev@example.com' }
  s.source       = { :git => 'https://github.com/lyswhut/lx-music-mobile.git', :tag => s.version.to_s }
  s.source_files = 'CarPlayBridge/**/*.{h,m}'
  s.frameworks   = 'CarPlay', 'UIKit'
  s.dependency   'React-Core'
  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/../LxMusicMobile"' }
  s.platform     = :ios, '15.0'
end
