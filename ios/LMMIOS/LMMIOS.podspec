Pod::Spec.new do |s|
  s.name         = 'LMMIOS'
  s.version      = '1.0.0'
  s.summary      = 'iOS LocalMediaMetadata for react-native-local-media-metadata'
  s.description  = 'iOS native implementation of LocalMediaMetadata (readMetadata/readPic/readLyric) missing from lyswhut fork'
  s.homepage     = 'https://github.com/yjje3658/lx-music-mobile'
  s.license      = { :type => 'MIT' }
  s.author       = { 'lx' => 'lx@example.com' }
  s.platform     = :ios, '11.0'
  s.source       = { :git => 'https://github.com/yjje3658/lx-music-mobile.git', :tag => 'v1.0.0' }
  s.source_files = '**/*.{h,m}'
  s.dependency   'React-Core'
  s.frameworks   = 'AVFoundation', 'CoreMedia'
end
