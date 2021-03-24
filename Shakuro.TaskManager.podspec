#
#
#

Pod::Spec.new do |s|
    s.name             = 'Shakuro.TaskManager'
    s.version          = '1.0'
    s.summary          = 'Shakuro Task Manager'
    s.homepage         = 'https://gitlab.com/shakuro-public/task-manager'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.authors          = {'Sanakabarabaka' => 'slaschuk@shakuro.com',
                          'wwwpix' => 'spopov@shakuro.com',
                          'apopov1988' => 'apopov@shakuro.com',
                          'vonipchenko' => 'vonipchenko@shakuro.com'}
    s.source           = { :git => 'https://gitlab.com/shakuro-public/task-manager.git', :tag => s.version }
    s.source_files     = 'Source/**/*'

    s.swift_version    = '5.0'
    s.ios.deployment_target = '10.0'

    s.dependency 'CommonCryptoModule', '1.0.2'

end
