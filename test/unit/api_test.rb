require File.join(File.dirname(__FILE__), 'test_helper')

describe ApipieBindings::API do

  let(:api) { ApipieBindings::API.new({:apidoc_cache_dir => 'test/unit/data', :apidoc_cache_name => 'architecture'}) }

  it "should provide resource" do
    result = api.resource(:architectures)
    result.must_be_kind_of ApipieBindings::Resource
  end

  it "should test if resource is available" do
    api.has_resource?(:architectures).must_equal true
  end

  it "should list resources" do
    api.resources.map(&:name).must_equal [:architectures]
  end

  # it "should have apidoc_cache_file available" do
  # end

  it "should call the method" do
    params = { :a => 1 }
    headers = { :content_type => 'application/json' }
    ApipieBindings::API.any_instance.expects(:http_call).with('get', '/api/architectures', params, headers, {})
    api.call(:architectures, :index, params, headers)
  end

  it "should call the method and fill in the params" do
    params = { :id => 1 }
    headers = { :content_type => 'application/json' }
    ApipieBindings::API.any_instance.expects(:http_call).with('get', '/api/architectures/1', {}, headers, {})
    api.call(:architectures, :show, params, headers)
  end

  it "should return values from examples in dry_run mode" do
    api.dry_run = true
    result = api.call(:architectures, :index)
    result.must_be_kind_of Array
  end

  it "should allow to set dry_run mode in config params" do
    api = ApipieBindings::API.new({
      :apidoc_cache_dir => 'test/unit/data',
      :apidoc_cache_name => 'architecture',
      :dry_run => true })
    result = api.call(:architectures, :index)
    result.must_be_kind_of Array
  end

  it "should allow to set fake response in config params" do
    api = ApipieBindings::API.new({
      :apidoc_cache_dir => 'test/unit/data',
      :apidoc_cache_name => 'architecture',
      :dry_run => true,
      :fake_params => { [:architectures, :index] => {:default => [] } }} )
    result = api.call(:architectures, :index)
    result.must_be_kind_of Array
  end

  it "should preserve file in args (#2)" do
    api = ApipieBindings::API.new({
      :apidoc_cache_dir => 'test/unit/data',
      :apidoc_cache_name => 'architecture',
      :dry_run => true})
    s = StringIO.new; s << 'foo'
    headers = {:content_type => 'multipart/form-data', :multipart => true}
    RestClient::Response.expects(:create).with() {
      |body, head, args| args == [:post, {:file => s}, headers]
    }
    result = api.http_call(:post, '/api/path', {:file => s}, headers, {:response => :raw})
  end

  it "should process nil response safely" do
    api.send(:process_data, nil).must_equal ''
  end

  it "should process empty response safely" do
    api.send(:process_data, '').must_equal ''
  end

  it "should process empty JSON response safely" do
    api.send(:process_data, '{}').must_equal({})
  end

  it "should process JSON response safely" do
    api.send(:process_data, '{"a" : []}').must_equal({'a' => []})
  end

  context "update_cache" do

    before :each do
      @dir = Dir.mktmpdir
      @api = ApipieBindings::API.new({:apidoc_cache_dir => @dir, :apidoc_cache_name => 'cache'})
      @api.stubs(:retrieve_apidoc).returns(nil)
      File.open(@api.apidoc_cache_file, "w") { |f| f.write(['test'].to_json) }
    end

    after :each do
      Dir["#{@dir}/*"].each { |f| File.delete(f) }
      Dir.delete(@dir)
    end

    it "should clean the internal cache when the name has changed" do
      @api.update_cache('new_name')
      @api.apidoc.must_equal nil
    end

    it "should clean the cache dir when the name has changed" do
      @api.update_cache('new_name')
      Dir["#{@dir}/*"].must_be_empty
    end

    it "should set the new cache name when the name has changed" do
      @api.update_cache('new_name')
      @api.apidoc_cache_file.must_equal File.join(@dir, 'new_name.json')
    end

    it "should not touch enything if the name is same" do
      @api.update_cache('cache')
      @api.apidoc.must_equal ['test']
    end

    # caching is turned off on server
    it "should not touch enything if the name is nil" do
      @api.update_cache(nil)
      @api.apidoc.must_equal ['test']
    end

    it "should load cache and its name from cache dir" do
      Dir["#{@dir}/*"].each { |f| File.delete(f) }
      FileUtils.cp('test/unit/data/architecture.json', File.join(@dir, 'api_cache.json'))
      api = ApipieBindings::API.new({:apidoc_cache_dir => @dir})
      api.apidoc_cache_name.must_equal 'api_cache'
    end
  end

  context "configuration" do
    it "should complain when no uri or cache dir is set" do
      proc {ApipieBindings::API.new({})}.must_raise ApipieBindings::ConfigurationError
    end

    it "should obey :apidoc_cache_base_dir to generate apidoc_cache_dir" do
      Dir.mktmpdir do |dir|
        api = ApipieBindings::API.new({:uri => 'http://example.com', :apidoc_cache_base_dir => dir})
        api.apidoc_cache_file.must_equal File.join(dir, 'http___example.com', 'default.json')
      end
    end
  end

end
