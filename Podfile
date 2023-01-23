source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'

use_frameworks!

workspace 'TaskManager'

target 'TaskManager_Framework' do
    project 'TaskManager_Framework.xcodeproj'
    pod 'Shakuro.CommonTypes', '1.1.4'
end

target 'TaskManager_Example' do
    project 'TaskManager_Example.xcodeproj'
    pod 'SwiftLint', '0.43.1'
    pod 'Shakuro.CommonTypes', '1.1.4'
    pod 'Shakuro.HTTPClient'
end
