require 'sinatra'
require 'zlib'
require 'rubygems/package'
require 'tmpdir'
require 'securerandom'
require 'yaml'


AUTH_TOKEN = SecureRandom.urlsafe_base64(40)
FLOCKER_KEY_DIR = ENV['FLOCKER_KEY_DIR'] || '/etc/flocker'
CLUSTER_CRT_NAME = ENV['FLOCKER_CLUSTER_CRT_NAME'] || "cluster.crt"
FLOCKER_CONTROL_HOST = ENV['FLOCKER_CONTROL_HOST'] || IO.popen('hostname -f').read.strip
FLOCKER_DATASET_BACKEND = ENV['FLOCKER_DATASET_BACKEND'] || "aws"
AWS_ACCESS_KEY_ID = ENV['AWS_ACCESS_KEY_ID'] || ""
AWS_SECRET_ACCESS_KEY = ENV['AWS_SECRET_ACCESS_KEY'] || ""

def generate_credentials
  creds = {}
  Dir.mktmpdir do |dir|
    system("flocker-ca create-node-certificate -i #{FLOCKER_KEY_DIR} -o #{dir}")
    cert = File.open(Dir.glob("#{dir}/*.crt")[0]).read
    key = File.open(Dir.glob("#{dir}/*.key")[0]).read
    cluster_key = File.open(File.join(FLOCKER_KEY_DIR, CLUSTER_CRT_NAME)).read
    creds.merge!({cert: cert, key: key, cluster_key: cluster_key})
  end
  creds
end

def agent_config(az)
  {"version" => 1,
   "control-service" => {
      "hostname" => FLOCKER_CONTROL_HOST, "port" => 4524
    },
   "dataset" => {
     "backend" => "aws",
     "region" => az[0..-2],
     "zone" => az,
     "access_key_id" => AWS_ACCESS_KEY_ID,
     "secret_access_key" => AWS_SECRET_ACCESS_KEY
   }
  }.to_yaml
end

def create_tokenfile(az)
  creds = generate_credentials
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
    agent_config_file = agent_config(az)
    tar.add_file_simple("agent.yml", 0600, agent_config_file.length) do |io|
      io.write(agent_config_file)
    end
  end
  tarfile.seek(0)
  tarfile
end

get '/token.tar' do
  if params.has_key?('AUTH_TOKEN') && params.has_key?('AZ')
    if params['AUTH_TOKEN'] == AUTH_TOKEN
      response.headers['content_type'] = "application/octet-stream"
      attachment("token.tar")
      response.write(create_tokenfile(params['AZ']))
    else
      halt 401, "Go away"
    end
  else
    halt 401, "Go away"
  end
end
