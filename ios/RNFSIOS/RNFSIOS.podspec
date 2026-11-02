Pod::Spec.new do |s|
  s.name         = 'RNFSIOS'
  s.version      = '1.0.0'
  s.summary      = 'iOS FileSystemModule for react-native-file-system'
  s.description  = 'iOS native implementation of FileSystemModule (Dirs/FileSystem) missing from lyswhut fork'
  s.homepage     = 'https://github.com/yjje3658/lx-music-mobile'
  s.license      = { :type => 'MIT' }
  s.author       = { 'lx' => 'lx@example.com' }
  s.platform     = :ios, '11.0'
  s.source       = { :git => 'https://github.com/yjje3658/lx-music-mobile.git', :tag => 'v1.0.0' }
  s.source_files = '**/*.{h,m}'
  s.dependency   'React-Core'
  s.libraries    = 'z'
end
