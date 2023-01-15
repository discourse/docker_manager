# Docker Manager

This plugin works with the Discourse docker image. It allows you to perform upgrades via the web UI and monitor activity in the container.

## Running tests

- Ruby
  - Run `RAILS_ENV=test bin/rails "plugin:spec[docker_manager]"` in your discourse directory
- JS
  - Run `RAILS_ENV=test bin/rails "plugin:qunit[docker_manager]"` in your discourse directory

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT
