## Docker Manager

This plugin works with the Discourse docker image. It allows you to perform upgrades via the web UI and monitor activity in the container.

## Development Notes

* Install `node.js`, `bower`, `grunt`
* Clone this repo to desired folder path
* In console, from folder path do `cd manager-client`, `npm install`, `bower install`
* Create a symlink for this folder in your local Discourse instance "plugins" folder (eg. `path/to/your/discourse_folder/plugins/discourse_manager`)
* Make sure your Discourse instance is running locally at port 3000 and you are logged in as Admin

## The Client App

* Install the client app dependencies:
  * `cd manager-client`
  * `npm install`
  * `bower install`
* Use `ember server --proxy "http://localhost:3000"` to proxy to your Discourse instance running on port 3000
  * If that gives errors, you may need to start your Discourse rails server like this: `bundle exec rails s -b 127.0.0.1`
* JUST open up a browser to port 4200 and you're off to the races!

The client application is built using [Ember CLI](http://www.ember-cli.com/).

To create a compiled version for distribution, run `./compile_client.sh` to compile the site and
move it into the proper directories.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT
