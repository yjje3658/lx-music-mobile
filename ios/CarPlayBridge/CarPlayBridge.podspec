Pod::Spec.new do |s|
  s.name             = 'CarPlayBridge'
  s.version          = '1.0.0'
  s.summary          = 'CarPlay support for LxMusicMobile'
  s.description      = 'Native CarPlay bridge for LxMusicMobile'
  s.homepage         = 'https://github.com/yijie3658/lx-music-mobile'
  s.license          = { :type => 'MIT' }
  s.author           = { 'lx-music' => 'lx@example.com' }
  s.source           = { :git => 'https://github.com/yijie3658/lx-music-mobile.git', :tag => s.version.to_s }
  s.platform         = :ios, '15.0'
  s.frameworks       = 'CarPlay'
  s.source_files     = 'CarPlayBridge/**/*.{h,m}'
  s.dependency 'React-Core'
  s.dependency 'React-RCTAppDelegate'
  s.dependency 'ReactNativeNavigation'
  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/../LxMusicMobile"' }
end
