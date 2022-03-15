require "ecr"

authorized_keys_path = "#{ENV["HOME"]}/authorized_keys"

File.open(authorized_keys_path, "w", 0o400) do |file|
  ENV.select { |key, value| key.includes?("SSHD_CLIENT") }.each do |key, value|
    user_name = key.split("_")[2]
    puts "🧑‍🎨 Adding user '#{user_name}' public key '#{value}' to '#{authorized_keys_path}'"
    file.puts "#{value} ( #{user_name} )"
  end
end

if File.file?("/etc/ssh/ssh_host_ed25519_key")
  puts "🕵️ Generating new /etc/ssh/ssh_host_ed25519_key"
  Process.new("ssh-keygen", ["-t", "ed25519", "-f", "/etc/ssh/ssh_host_ed25519_key", "-N", "''"], output: Process::Redirect::Pipe)
end

if File.file?("/etc/ssh/ssh_host_rsa_key")
  puts "🕵️ Generating new /etc/ssh/ssh_host_rsa_key"
  Process.new("ssh-keygen", ["-t", "rsa", "-b", "4096", "-f", "/etc/ssh/ssh_host_rsa_key", "-N", "''"], output: Process::Redirect::Pipe)
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
