require "ecr"

require "file_utils"

client_env_prefix = "SSH_CLIENT"
client_user_id = ENV["SSH_USER_ID"]
client_group_id = ENV["SSH_GROUP_ID"]
dot_ssh_folder_path = "#{ENV["SSH_HOMEDIR"]}/.ssh"

FileUtils.mkdir_p(dot_ssh_folder_path, 0o700)
File.chown(dot_ssh_folder_path, client_user_id, client_group_id)

authorized_keys_path = "#{dot_ssh_folder_path}/authorized_keys"

File.open(authorized_keys_path, "w", 0o400) do |file|
  ENV.select { |key, value| key.includes?(client_env_prefix) }.each do |key, value|
    user_name = key.split("_")[2]
    puts "🧑‍🎨 Adding user '#{user_name}' public key '#{value}' to '#{authorized_keys_path}'"
    file.puts "#{value} ( #{user_name} )"
  end
end

File.chown(authorized_keys_path, client_user_id, client_group_id)

if !File.exists?("/etc/ssh/ssh_host_ed25519_key")
  puts "🕵️ Generating new /etc/ssh/ssh_host_ed25519_key"
  Process.run("ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''", output: Process::Redirect::Pipe, shell: true)
end

if !File.exists?("/etc/ssh/ssh_host_rsa_key")
  puts "🕵️ Generating new /etc/ssh/ssh_host_rsa_key"
  Process.run("ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ''", output: Process::Redirect::Pipe, shell: true)
end

puts "🩹 Generating sshd config with port '#{ENV["SSHD_PORT"]}'"
class SshdConfig
  def initialize(@port : String)
  end

  ECR.def_to_s "sshd_config.ecr"
end

File.open("/etc/ssh/sshd_config", "w", 0o400) do |file|
  file.puts SshdConfig.new(ENV["SSHD_PORT"]).to_s
end

puts "🏁 All done starting sshd"
Process.exec("/usr/sbin/sshd", ["-D", "-e"])