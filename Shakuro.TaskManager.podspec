Pod::Spec.new do |s|
    s.name             = 'Shakuro.TaskManager'
    s.version          = '0.0.7'
    s.summary          = 'Shakuro Task Manager'
    s.homepage         = 'https://github.com/shakurocom/TaskManager'
    s.license          = { :type => "MIT", :file => "LICENSE.md" }
    s.authors          = {'apopov1988' => 'apopov@shakuro.com', 'wwwpix' => 'spopov@shakuro.com'}
    s.source           = { :git => 'https://github.com/shakurocom/TaskManager.git', :tag => s.version }
    s.source_files     = 'Source/*', 'Source/**/*'

    s.swift_version    = ['5.1', '5.2', '5.3']
    s.ios.deployment_target = '13.0'

    s.dependency 'Shakuro.HTTPClient', '1.0.1'
    s.dependency 'Shakuro.CommonTypes', '1.0.1'
    s.dependency 'CommonCryptoModule', '1.0.2'

end