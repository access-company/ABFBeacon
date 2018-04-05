Pod::Spec.new do |s|
  s.name             = "ABFBeacon"
  s.version          = "1.4.0"
  s.summary          = "ACCESS Beacon Framework Library"
  s.homepage         = "https://github.com/access-company/ABFBeacon"
  s.license          = { :type => 'MIT', :file => 'iOS/LICENSE.txt' }
  s.author           = 'ACCESS CO., LTD'
  s.source           = { :git => "https://github.com/access-company/ABFBeacon.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'iOS/ABFBeacon/*.{h,m}'
  s.resource_bundles = {
    'ABFBeacon' => ['Pod/Assets/*.png']
  }
end
