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

  # Configuration files
  if ENV['PKG_TYPE'] == "rpm" || ENV['PKG_TYPE'] == "deb"
    command "sudo cp packaging/#{ENV['DISTRO']}/datadog-agent.init /etc/init.d/datadog-agent"
    command "sudo mkdir -p /etc/dd-agent"
    command "sudo cp packaging/supervisor.conf /etc/dd-agent/supervisor.conf"
    command "sudo cp datadog.conf.example /etc/dd-agent/datadog.conf.example"
    command "sudo cp -R conf.d /etc/dd-agent/"
    command "sudo mkdir -p /etc/dd-agent/checks.d/"
  elsif ENV['PKG_TYPE'] == "dmg"
    command "mkdir #{install_dir}/conf #{install_dir}/launchd"
    command "cp packaging/supervisor.conf #{install_dir}/conf/supervisor.conf"
    command "sed -in '/dd-agent/d' #{install_dir}/conf/supervisor.conf"
    command "cp datadog.conf.example #{install_dir}/conf/datadog.conf.example"
    command "cp -R conf.d #{install_dir}/conf/"
    command "cp packaging/datadog-agent/osx/datadog-agent #{install_dir}/bin"
    command "cp packaging/datadog-agent/osx/com.datadoghq.Agent.plist.example #{install_dir}/launchd"
    command "mkdir -p #{install_dir}/conf/checks.d/"
  end
end
