require 'sinatra'
require 'zlib'
require 'rubygems/package'
require 'tmpdir'
require 'securerandom'
require 'yaml'
require_relative "lib/creds.rb"
require_relative "lib/hash.rb"

AUTH_TOKEN = SecureRandom.urlsafe_base64(40)
FLOCKER_KEY_DIR = ENV['FLOCKER_KEY_DIR'] || '/etc/flocker'
FLOCKER_CLUSTER_NAME = ENV['FLOCKER_CLUSTER_NAME'] || "cluster"
FLOCKER_CONTROL_HOST = ENV['FLOCKER_CONTROL_HOST'] || IO.popen('hostname -f').read.strip
FLOCKER_GENERATE_VAULT = ENV['FLOCKER_GENERATE_VAULT'] || "false"

if FLOCKER_GENERATE_VAULT == "true"
  FileUtils.mkdir_p(FLOCKER_KEY_DIR)
  system("cd #{FLOCKER_KEY_DIR} && flocker-ca initialize #{FLOCKER_CLUSTER_NAME}")
  system("flocker-ca create-control-certificate -i #{FLOCKER_KEY_DIR} -o #{FLOCKER_KEY_DIR} #{FLOCKER_CONTROL_HOST}")
  control_cert= Dir.glob(File.join(FLOCKER_KEY_DIR, "control*.crt")).first
  control_key= Dir.glob(File.join(FLOCKER_KEY_DIR, "control*.key")).first
  FileUtils.mv(control_cert, "#{FLOCKER_KEY_DIR}/control.crt")
  FileUtils.mv(control_key, "#{FLOCKER_KEY_DIR}/control.key")
  system("flocker-ca create-api-certificate -i #{FLOCKER_KEY_DIR} -o #{FLOCKER_KEY_DIR} plugin")
  FlockerCert.new.write_node_credentials
end

def create_tokenfile(opts)
  cert_obj = FlockerCert.new(opts)
  creds =  cert_obj.node_credentials
  tarfile = StringIO.new
  Gem::Package::TarWriter.new(tarfile) do |tar|
    cert = creds[:cert]
    tar.add_file_simple("node.crt", 0600, creds[:cert].length) do |io|
      io.write(creds[:cert])
    end
    keystr = creds[:key]
    tar.add_file_simple("node.key", 0600, creds[:key].length) do |io|
      io.write(creds[:key])
    end
    cluster_key = creds[:cluster_key]
    tar.add_file_simple("cluster.crt", 0600, creds[:cluster_key].length) do |io|
      io.write(creds[:cluster_key])
    end
    agent_config_file = cert_obj.agent_config
    tar.add_file_simple("agent.yml", 0600, agent_config_file.length) do |io|
      io.write(agent_config_file)
    end
    plugin_cert = cert_obj.plugin_credentials[:cert]
    tar.add_file_simple("plugin.crt", 0600, plugin_cert.length) do |io|
      io.write(plugin_cert)
    end
    plugin_key = cert_obj.plugin_credentials[:key]
    tar.add_file_simple("plugin.key", 0600, plugin_key.length) do |io|
      io.write(plugin_key)
    end
  end
  tarfile.seek(0)
  tarfile
end

post '/credentials.tar' do
  if params.has_key?('AUTH_TOKEN') && params.has_key?('region') && params.has_key?('zone') 
    if params['AUTH_TOKEN'] == AUTH_TOKEN
      response.headers['content_type'] = "application/octet-stream"
      attachment("credentials.tar")
      response.write(create_tokenfile({"region" => params['region'], "zone" => params['zone']}))
    else
      halt 401, "Go away"
    end
  else
    halt 401, "Go away"
  end
end

post "/agent.yml" do
  if params.has_key?('AUTH_TOKEN') && params.has_key?('region') && params.has_key?('zone') 
    if params['AUTH_TOKEN'] == AUTH_TOKEN
    FlockerCert.new({"region" => params['region'], "zone" => params['zone']}).agent_config.to_s
    end
  else
    halt 401, "go away"
  end
end
