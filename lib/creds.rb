class FlockerCert

  def initialize(opts = nil)
    @opts = opts
  end

  def flocker_agent_dataset_envs
    ENV.select {|x| x =~ /FLOCKER_AGENT_DATASET_.*/}.transform_keys {|k| k.gsub("FLOCKER_AGENT_DATASET_","").downcase}
  end

  def flocker_agent_dataset
    flocker_agent_dataset_envs.merge!(@opts)
  end
  def node_credentials
    creds = {}
    Dir.mktmpdir do |dir|
      system("flocker-ca create-node-certificate -i #{FLOCKER_KEY_DIR} -o #{dir}")
      cert = File.open(Dir.glob("#{dir}/*.crt")[0]).read
      key = File.open(Dir.glob("#{dir}/*.key")[0]).read
      cluster_key = File.open(File.join(FLOCKER_KEY_DIR, "#{FLOCKER_CLUSTER_NAME}.crt")).read
      creds.merge!({cert: cert, key: key, cluster_key: cluster_key})
    end
    creds
  end

  def plugin_credentials
    creds = {
      cert: File.open("#{FLOCKER_KEY_DIR}/plugin.crt").read, 
      key: File.open("#{FLOCKER_KEY_DIR}/plugin.key").read
    }
  end

  def write_node_credentials
    creds = node_credentials
    File.open("#{FLOCKER_KEY_DIR}/node.crt", "w") do |file|
      file << creds[:cert]
    end
    File.open("#{FLOCKER_KEY_DIR}/node.key", "w") do |file|
      file << creds[:key]
    end
  end

  def agent_config
    {"version" => 1,
     "control-service" => {
      "hostname" => FLOCKER_CONTROL_HOST, "port" => 4524
    },
    "dataset" => flocker_agent_dataset
    }.to_yaml
  end

  def write_agent_config(filename)
    File.open(filename, "w") do |file|
      file << agent_config
    end
  end

end
