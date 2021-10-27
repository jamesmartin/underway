require_relative "../test_helper"
require "underway/sinatra"

class SinatraTest < Minitest::Test
  include Sinatra::Underway

  def setup
    Underway::Settings.configure do |config|
      config.github_api_host = "https://test.example.com"
    end

    @token = "fake"
    stub_request(:get, "https://test.example.com/installation/repositories")
      .with(
        headers: {
          "Accept" => "application/vnd.github.machine-man-preview+json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "token #{@token}",
          "Content-Type" => "application/json",
          "User-Agent" => "Octokit Ruby Gem #{Octokit::VERSION}"
        }
      )
      .to_return(status: 200, body: {"test" => true}.to_json, headers: {})
  end

  def test_can_invoke_gh_api_with_kwargs
    res = gh_api("/installation/repositories", headers: { authorization: "token #{@token}" })
    refute_nil res
  end
end
