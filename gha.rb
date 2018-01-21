require "sinatra"

get "/" do
  erb <<~EOS
    <h2>Interesting routes:</h2>
    <pre>
      <li>/             => This homepage</li>
      <li>/user_authz   => User authorization callback URL</li>
      <li>/setup        => (Optional) setup URL</li>
      <li>/hook         => Receives incoming installation and modification Webhooks</li>
    </pre>
  EOS
end
