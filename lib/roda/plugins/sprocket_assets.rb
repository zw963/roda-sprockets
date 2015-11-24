require 'roda'
require 'sprockets'
require 'sprockets-helpers'

class Roda
  module RodaPlugins
    module SprocketAssets
      DEFAULTS = {
        sprockets:      Sprockets::Environment.new,
        precompile:     %w(app.js app.css *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2),
        prefix:         %w(assets vendor/assets),
        root:           Dir.pwd,
        path:           -> { File.join(public_folder, 'assets') },
        path_prefix:    nil,
        protocol:       :http,
        css_compressor: nil,
        js_compressor:  nil,
        host:           nil,
        digest:         true,
        debug:          false
      }.freeze

      def self.load_dependencies(app, _opts = nil)
        app.plugin :environments
      end

      def self.configure(app, plugin_opts = {})
        app.opts[:sprocket_assets] ? app.opts[:sprocket_assets].merge!(plugin_opts) : app.opts[:sprocket_assets] = plugin_opts.dup
        opts = app.opts[:sprocket_assets].merge! plugin_opts
        DEFAULTS.each { |k, v| opts[k] = v unless opts.key?(k) }

        opts[:prefix].each do |prefix|
          # Support absolute asset paths
          # https://github.com/kalasjocke/sinatra-asset-pipeline/pull/54
          paths = if Pathname.new(prefix).absolute?
            Dir[File.join(prefix, '*')]
          else
            Dir[File.join(opts[:root], prefix, '*')]
          end
          paths.each { |path| opts[:sprockets].append_path path }
        end

        Sprockets::Helpers.configure do |config|
          config.environment = opts[:sprockets]
          config.digest      = opts[:digest]
          config.prefix      = opts[:path_prefix] unless opts[:path_prefix].nil?
          config.debug       = opts[:debug]
        end

        app.configure :staging, :production do
          opts[:sprockets].css_compressor = opts[:css_compressor] unless opts[:css_compressor].nil?
          opts[:sprockets].js_compressor  = opts[:js_compressor] unless opts[:js_compressor].nil?

          Sprockets::Helpers.configure do |config|
            config.manifest   = Sprockets::Manifest.new(opts[:sprockets], opts[:path])
            config.prefix     = opts[:path_prefix] unless opts[:path_prefix].nil?
            config.protocol   = opts[:protocol]
            config.asset_host = opts[:host] unless opts[:host].nil?
          end
        end
      end

      module ClassMethods
        def sprocket_assets_opts
          opts[:sprocket_assets]
        end
      end

      module InstanceMethods
        include Sprockets::Helpers

        def sprocket_assets_opts
          self.class.sprocket_assets_opts
        end
      end

      module RequestClassMethods
        def sprocket_assets_regexp
          %r{#{Sprockets::Helpers.prefix[1..-1]}/(.*)}
        end
      end

      module RequestMethods
        def sprocket_assets
          scope.class.configure :test, :development do
            get self.class.sprocket_assets_regexp do |path|
              env_sprockets = scope.request.env.dup
              env_sprockets['PATH_INFO']  = path
              status, headers, response = scope.sprocket_assets_opts[:sprockets].call env_sprockets
              scope.response.status = status
              scope.response.headers.merge! headers
              response.is_a?(Array) ? response.join('\n') : response.to_s
            end
          end
        end
      end
    end

    register_plugin :sprocket_assets, SprocketAssets
  end
end
