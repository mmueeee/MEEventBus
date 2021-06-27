Pod::Spec.new do |s|
  s.name         = 'MEEventBus'
  s.version      = '1.0.0'
  s.summary      = '基于协议的事件总线'
  s.description  = '基于协议的事件总线'
  s.homepage     = 'https://github.com/mmueeee/MEEventBus'
  s.license      = 'MIT'
  s.author       = { 'muee' => 'mmuee88@163.com' }
  s.platform     = :ios, '8.0'
  s.source       = { 
    :git => "https://github.com/mmueeee/MEEventBus.git", 
    :tag => s.version.to_s 
  }
  s.requires_arc = true

  s.source_files = '**/*.{h,m}'
end
