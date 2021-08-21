# Roda::Sprockets

This Roda plugin provides support for integrating Sprockets with your Roda codebase.

This is a fork of [roda-sprocket_assets](https://github.com/cj/roda-sprocket_assets).
This release supports Roda 3.x and Sprockets 3.x and 4.x.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'roda-sprockets'
```

And then execute:

    $ bundle

## Usage

```ruby
class App < Roda
   plugin :sprockets, precompile: %w(site.js site.css),
                      opal: true,
                      debug: true
   plugin :public

   route do |r|
     r.public
     r.sprockets
   end
end
```

### Parameters for the plugin:

* `precompile` - an array of files that you want to precompile
* `prefix` (relative to the `root`, which is `app.opts[:root]` by default,
  but also supports absolute paths) - an array of directories where your
  assets are located, by default: `%w(assets vendor/assets)`.
* `root` - a filesystem root directory of your app. By default, same as
  `app.opts[:root]`, that is: `Dir.pwd`.
* `public_path` - filesystem path to a place, where precompiled assets will be
  stored, by default: `public/assets` (it should be a directory from which `:public`
  plugin takes files + `path_prefix`)
* `path_prefix` - a Roda prefix of your assets directory. By default: `/assets`
* `protocol` - either :http (default) or :https.
* `css_compressor`, `js_compressor` - pick a compressor of your choice.
* `host` - for hosting your assets on a different server
* `digest` (bool) - digest your assets for unique filenames, default: true
* `opal` (bool) - Opal support, default: false
* `debug` (bool) - debug mode, default: false
* `cache` - a `Sprockets::Cache` instance, default: nil (no cache)

### Templates:

In your layout.erb (take note of the stylesheet_tag and javascript_tag):

```erb
<!doctype html>
<html>
<head>
<meta charset='utf-8'>
<title>Website</title>
<%= stylesheet_tag 'site' %>
</head>
<body>
<h1>Website</h1>
<%= yield %>
<%= javascript_tag 'site' %>
</body>
</html>
```

### Opal support:

Opal is the first citizen of this plugin. Add `opal` and `opal-browser`
gems, `require 'opal'`, `require 'opal-browser'` before this plugin gets
loaded. Create `assets/js/site.rb`:

```ruby
require 'opal'
require 'opal-browser'

$document.body << DOM {
  div "Hello world!"
}
```

You will need to tell Opal to load this file. Add this in your template
after everything has been loaded (after your `javascript_tag` call, it is
needed too!):

```erb
<%= opal_require 'site' %>
```

Note that it won't be needed for plain Javascript use, only Opal needs that
line.

### Caching:

To speed up page loads during development, you can enable cache. Be warned,
there are some caveats with how Sprockets cache works. This will improve your
experience, but be prepared for some rough edges.

To enable memory cache, add an argument to your plugin config:

```ruby
cache: Sprockets::Cache::MemoryStore.new(65536)
```

To enable filesystem cache, for it to persist across application restarts,
add an argument to your plugin config:

```ruby
cache: Sprockets::Cache::FileStore.new("var/cache/")
```

Remember: with filesystem cache problems may happen if you, for instance,
update your Gems. You will then have to remove the cache for it to get
repopulated.

### Rake precompilation tasks:

In your Rakefile:

```ruby
require_relative 'app'
require 'roda/plugins/sprockets_task'

Roda::RodaPlugins::Sprockets::Task.define!(App)
```

And launch: `rake assets:precompile` or `rake assets:clean`

## Contributing

1. Fork it ( https://github.com/hmdne/roda-sprockets/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
