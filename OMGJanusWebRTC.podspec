#
# Be sure to run `pod lib lint OMGJanusWebRTC.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'OMGJanusWebRTC'
    s.version          = '0.2.0'
    s.summary          = 'OMGJanusWebRTC.'
    s.swift_version    = '4.2'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    TODO: Add long description of the pod here.
    DESC
    
    s.homepage         = 'https://github.com/OMGHydeGuo/JanusWebRTC'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Hyde Guo' => 'guohyde@onwardsmg.com' }
    s.source           = { :git => 'https://github.com/OMGHydeGuo/JanusWebRTC.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '10.0'
    
    s.source_files = 'OMGJanusWebRTC/Classes/**/*'
    
    # s.resource_bundles = {
    #   'OMGJanusWebRTC' => ['OMGJanusWebRTC/Assets/*.png']
    # }
    
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'WebRTC'
    s.dependency 'Starscream'
    
end
