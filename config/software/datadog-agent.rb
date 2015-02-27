name "datadog-agent"

local_agent_repo = ENV['LOCAL_AGENT_REPO']
if local_agent_repo.nil? || local_agent_repo.empty?
  source git: "https://github.com/DataDog/dd-agent.git"
else
  # For local development
  source path: ENV['LOCAL_AGENT_REPO']
end

agent_branch = ENV['AGENT_BRANCH']
if agent_branch.nil? || agent_branch.empty?
  default_version 'master'
else
  default_version agent_branch
end

relative_path "dd-agent"
always_build true

env = {
  "PATH" => "#{install_dir}/embedded/bin/:#{ENV['PATH']}"
}

# Avoid relly lobg lines
app_temp_dir = "#{install_dir}/agent/dist/Datadog\\ Agent.app/Contents"
pyside_build_dir =  "#{install_dir}/agent/build/bdist.macosx-10.5-intel/python2.7-standalone/app/collect/PySide"
command_fix_shiboken = "install_name_tool -change @rpath/libshiboken-python2.7.1.2.dylib"\
                      " @executable_path/../Frameworks/libshiboken-python2.7.1.2.dylib "
command_fix_pyside = "install_name_tool -change @rpath/libpyside-python2.7.1.2.dylib"\
                      " @executable_path/../Frameworks/libpyside-python2.7.1.2.dylib "\

build do
  license "https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE"
  # Agent code
  command "mkdir -p #{install_dir}/agent/"
  command "cp -R checks.d #{install_dir}/agent/"
  command "cp -R checks #{install_dir}/agent/"
  command "cp -R dogstream #{install_dir}/agent/"
  command "cp -R resources #{install_dir}/agent/"
  command "cp -R utils #{install_dir}/agent/"
  command "cp *.py #{install_dir}/agent/"
  command "cp datadog-cert.pem #{install_dir}/agent/"

  # Build the app
  if ENV['PKG_TYPE'] == "dmg"
    command "cp -R packaging/datadog-agent/win32/install_files/guidata/images #{install_dir}/agent"
    command "cp win32/gui.py #{install_dir}/agent"
    command "cp win32/status.html #{install_dir}/agent"
    command "mkdir -p #{install_dir}/agent/packaging"
    command "cp packaging/osx/app/* #{install_dir}/agent/packaging"
    # Shipping supervisor
    command "cp #{install_dir}/embedded/lib/python2.7/site-packages/supervisor-*/supervisor/supervisor{d,ctl}.py"\
            " #{install_dir}/agent"
    command "cd #{install_dir}/agent && "\
            "#{install_dir}/embedded/bin/python #{install_dir}/agent/setup.py py2app"\
            " && cd -", :env => env
    command "cp #{install_dir}/bin/gohai #{app_temp_dir}/MacOS"
    command "cp packaging/osx/datadog-agent #{app_temp_dir}/MacOS"
    command "chmod a+x #{app_temp_dir}/MacOS/datadog-agent"
    # Time to patch the install, see py2app bug: (dependencies to system PySide)
    # https://bitbucket.org/ronaldoussoren/py2app/issue/143/resulting-app-mistakenly-looks-for-pyside
    command "cp #{pyside_build_dir}/libshiboken-python2.7.1.2.dylib #{app_temp_dir}/Frameworks"
    command "cp #{pyside_build_dir}/libpyside-python2.7.1.2.dylib #{app_temp_dir}/Frameworks"
    command "chmod a+x #{app_temp_dir}/Frameworks/{libpyside,libshiboken}-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir}/Frameworks/libpyside-python2.7.1.2.dylib"
    command "install_name_tool -change /usr/local/lib/QtCore.framework/Versions/4/QtCore "\
            "@executable_path/../Frameworks/QtCore.framework/Versions/4/QtCore "\
            "#{app_temp_dir}/Frameworks/libpyside-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_shiboken} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"
    command "#{command_fix_pyside} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_pyside} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"

    # And finally
    command "mv #{install_dir}/agent/dist/Datadog\\ Agent.app #{install_dir}"
  end

  # Configuration files
  if ENV['PKG_TYPE'] == "rpm" || ENV['PKG_TYPE'] == "deb"
    command "sudo cp packaging/#{ENV['DISTRO']}/datadog-agent.init /etc/init.d/datadog-agent"
    command "sudo mkdir -p /etc/dd-agent"
    command "sudo cp packaging/supervisor.conf /etc/dd-agent/supervisor.conf"
    command "sudo cp datadog.conf.example /etc/dd-agent/datadog.conf.example"
    command "sudo cp -R conf.d /etc/dd-agent/"
    command "sudo mkdir -p /etc/dd-agent/checks.d/"
  elsif ENV['PKG_TYPE'] == "dmg"
    command "cp packaging/osx/supervisor.conf #{install_dir}/Datadog\\ Agent.app/Contents/Resources"
    command "cp datadog.conf.example #{install_dir}/Datadog\\ Agent.app/Contents/Resources/datadog.conf.example"
    command "cp -R conf.d #{install_dir}/Datadog\\ Agent.app/Contents/Resources/"
    command "cp packaging/osx/com.datadoghq.Agent.plist.example #{install_dir}/Datadog\\ Agent.app/Contents/Resources/"
    command "mv #{install_dir}/licenses #{install_dir}/Datadog\\ Agent.app/Contents/Resources/"
    command "mv #{install_dir}/sources #{install_dir}/Datadog\\ Agent.app/Contents/Resources/"
    command "rm -rf #{install_dir}/agent #{install_dir}/embedded #{install_dir}/bin"
  end
end
