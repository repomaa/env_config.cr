# EnvConfig

Allows easy definition of application configs based on env vars. Supports
string values and all types that have a constructor `new(value : String)`.
Allows defining converters for more complex types (see usage). Inspired by
`JSON::Serializable`.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  env_config:
    github: jreinert/env_config.cr
```

## Usage

```crystal
require "env_config"
require "uri"

module MyApp
  def self.config
    @@config ||= Config.new(ENV, prefix: "MY_APP")
  end

  class Config
    include EnvConfig

    getter server : ServerConfig

    @[EnvConfig::Setting(key: "db")]
    getter database : DatabaseConfig

    class ServerConfig
      include EnvConfig

      getter host : String = "localhost"
      getter port : Int32 = 3000
      getter reuse_port : Bool
    end

    class DatabaseConfig
      include EnvConfig

      getter host : String = "localhost"
      getter port : Int32 = 6543
      getter name : String
      getter username : String?
      getter password : String?

      def uri
        URI.parse("postgres://#{host}:#{port}/#{name}").tap do |uri|
          username.try(&uri.username=)
          password.try(&uri.password=)
        end
      end
    end
  end
end
```

``` shell
$> MY_APP_SERVER_HOST=0.0.0.0 MY_APP_SERVER_REUSE_PORT=1 MY_APP_DB_NAME=my_app bin/my_app
```

## Development

If you find bugs or type conversions missing please let me know or fix/add
support for them yourself. Pull requests welcome! 

## Contributing

1. Fork it (<https://github.com/jreinert/env_config.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [jreinert](https://github.com/jreinert) Joakim Reinert - creator, maintainer
