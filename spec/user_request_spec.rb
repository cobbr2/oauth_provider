describe "A User Request" do
  it "can be authorized" do
    provider = create_provider
    consumer = provider.add_consumer("foo")
    user_request = consumer.issue_request("oob")
    user_request.authorize
    consumer.find_user_request(user_request.shared_key).should be_authorized
  end

  it "has its own callback" do
    provider = create_provider
    consumer = provider.add_consumer("http://oauth-provider.example.com")
    user_request = consumer.issue_request(consumer.callback + "/abcdef/ghijklmnopqrstuvwxyz/0123456")
    consumer.find_user_request(user_request.shared_key).callback.index(consumer.callback + "/abcdef").should == 0
  end

  it "says it verified the callback" do
    provider = create_provider
    consumer = provider.add_consumer("http://oauth-provider.example.com")
    user_request = consumer.issue_request(consumer.callback + "/abcdef")
    consumer.find_user_request(user_request.shared_key).query_string.should =~ /[&?]oauth_callback_verified=true/
  end

  describe "which has been authorized" do
    it "can be upgraded" do
      provider = create_provider
      consumer = provider.add_consumer("foo")
      user_request = consumer.issue_request("oob")
      user_request.authorize(user_info)
      upgrade_request = { 'parameters' => { 'oauth_verifier' => user_request.verifier }}
      user_access = user_request.upgrade(upgrade_request)
      consumer.find_user_access(user_access.shared_key).should == user_access
    end

    it "can be upgraded with a custom token" do
      provider = create_provider
      consumer = provider.add_consumer("foo")
      user_request = consumer.issue_request("oob",true)
      upgrade_request = { 'parameters' => { 'oauth_verifier' => user_request.verifier }}
      user_access = user_request.upgrade(upgrade_request, OAuthProvider::Token.new("shared key", "secret key"))
      user_access.shared_key.should == "shared key"
      user_access.secret_key.should == "secret key"
    end

    it "provides a verifier with its callback" do
      provider = create_provider
      consumer = provider.add_consumer("http://my.example.com/callback")
      user_request = consumer.issue_request("http://my.example.com/callback/nob")
      user_request.authorize
      user_request.callback.should =~ /oauth_verifier=[^&]+/
    end

    it "provides its own key as oauth_token on its callback" do
      provider = create_provider
      consumer = provider.add_consumer("http://my.example.com/callback")
      user_request = consumer.issue_request("http://my.example.com/callback/nob")
      user_request.authorize
      user_request.callback.should =~ /oauth_token=([^&]+)/
      match = user_request.callback.match(/oauth_token=([^&]+)/)[1]
      match.should == user_request.token.shared_key
    end

    it "saves its verifier for later comparison" do
      provider = create_provider
      consumer = provider.add_consumer("http://my.example.com/callback")
      user_request = consumer.issue_request("http://my.example.com/callback/nob")
      user_request.authorize
      saved_request = consumer.find_user_request(user_request.token.shared_key)
      saved_request.verifier.should == user_request.verifier
    end
  end

  describe "which has not been authorized" do
    it "cannot be upgraded" do
      provider = create_provider
      consumer = provider.add_consumer("foo")
      user_request = consumer.issue_request("oob")
      upgrade_request = { 'parameters' => { 'oauth_verifier' => user_request.verifier }}
      lambda { user_request.upgrade(upgrade_request) }.
        should raise_error(OAuthProvider::UserRequestNotAuthorized)
    end
  end

  describe "which has been upgraded" do
    it "has been destroyed" do
      provider = create_provider
      consumer = provider.add_consumer("foo")
      user_request = consumer.issue_request("oob")
      user_request.authorize
      upgrade_request = { 'parameters' => { 'oauth_verifier' => user_request.verifier }}
      user_request.upgrade(upgrade_request)

      lambda { consumer.find_user_request(user_request.shared_key) }.
        should raise_error(OAuthProvider::UserRequestNotFound)
    end
  end
end
