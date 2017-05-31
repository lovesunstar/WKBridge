#
# Be sure to run `pod lib lint WKBridge.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WKBridge'
  s.version          = '0.2.1'
  s.summary          = '在 WKWebView 中 提供 JS 和 Native 交互的方法'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
WKWebView 通过使用 WKScriptMessageHandler 极大简化了 JS 和 Native 通信的方法。WKScript 对 WKScriptMessageHandler 进行了封装，并且提供 JS 调用 Native 的方法，让 JS 和 Native 的交互更完美。
                       DESC

  s.homepage         = 'https://github.com/lovesunstar/WKBridge'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lovesunstar' => 'lovesunstar@sina.com' }
  s.source           = { :git => 'https://github.com/lovesunstar/WKBridge.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_lovesunstar'

  s.ios.deployment_target = '8.0'

  s.source_files = 'WKBridge/Classes/**/*'
  
  s.resource_bundles = {
    'WKBridge' => ['WKBridge/Assets/*.js']
  }

  s.frameworks = 'UIKit', 'WebKit'

end
