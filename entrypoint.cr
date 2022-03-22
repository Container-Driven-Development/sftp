require "ecr"

require "file_utils"

client_env_prefix = "SSH_CLIENT"
client_user_id = ENV["SSH_USER_ID"].to_i
client_group_id = ENV["SSH_GROUP_ID"].to_i
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

puts "🩹 Generating sshd config with port '#{ENV["SSHD_PORT"]}'"
class SshdConfig
  def initialize(@port : String, @ssh_enabled : Bool)
  end

  ECR.def_to_s "sshd_config.ecr"
end

File.open("/etc/ssh/sshd_config", "w", 0o400) do |file|
  file.puts SshdConfig.new(ENV["SSHD_PORT"], (ENV["SSHD_ENABLE_SSH"] != "true")).to_s
end

puts "🏁 All done starting sshd"
Process.exec("/usr/sbin/sshd", ["-D", "-e"])
