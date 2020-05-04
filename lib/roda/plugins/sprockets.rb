require 'roda'
require 'sprockets'
require 'sprockets-helpers'

class Roda
  module RodaPlugins
    module Sprockets
      DEFAULTS = {
        sprockets:      nil,
        precompile:     %w(app.js app.css *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2),
        prefix:         %w(assets vendor/assets),
        root:           false,
        public_path:    false,
        path_prefix:    "/assets",
        protocol:       :http,
        css_compressor: nil,
        js_compressor:  nil,
        host:           nil,
        digest:         true,
        opal:           false,
        debug:          false
      }.freeze

      def self.load_dependencies(app, _opts = nil)
        app.plugin :environments
      end

      def self.configure(app, plugin_options = {})
        if app.opts[:sprockets]
          app.opts[:sprockets].merge!(plugin_options)
        else
          app.opts[:sprockets] = plugin_options.dup
        end
        options = app.opts[:sprockets].merge! plugin_options
        DEFAULTS.each { |k, v| options[k] = v unless options.key?(k) }

        options[:root] = app.opts[:root] if !options[:root]

        %i(root public_path).each { |type| raise "#{type} needs to be set." unless options[type] }

        # opal-sprockets registers engines when required, but if we create Sprockets::Environment before
        # requiring that, they don't get registered
        require 'opal/sprockets' if options[:opal]
        options[:sprockets] ||= ::Sprockets::Environment.new

        options[:prefix].each do |prefix|
          # Support absolute asset paths
          # https://github.com/kalasjocke/sinatra-asset-pipeline/pull/54
          if prefix.end_with? '/'
            paths = if Pathname.new(prefix).absolute?
              Dir[File.join(prefix)]
            else
              Dir[File.join(options[:root], prefix)]
            end
          else
            paths = if Pathname.new(prefix).absolute?
              Dir[File.join(prefix, '*')]
            else
              Dir[File.join(options[:root], prefix, '*')]
            end
          end

          paths.each do |path|
            options[:sprockets].append_path path
          end
        end

        if options[:opal]
          Opal.paths.each do |path|
            options[:sprockets].append_path path
          end
        end

        ::Sprockets::Helpers.configure do |config|
          config.environment = options[:sprockets]
          config.digest      = options[:digest]
          config.prefix      = options[:path_prefix] unless options[:path_prefix].nil?
          config.debug       = options[:debug]
        end

        app.configure :staging, :production do
          options[:sprockets].css_compressor = options[:css_compressor] unless options[:css_compressor].nil?
          options[:sprockets].js_compressor  = options[:js_compressor] unless options[:js_compressor].nil?

          ::Sprockets::Helpers.configure do |config|
            config.manifest   = Sprockets::Manifest.new(options[:sprockets], options[:public_path])
            config.prefix     = options[:path_prefix] unless options[:path_prefix].nil?
            config.protocol   = options[:protocol]
            config.asset_host = options[:host] unless options[:host].nil?
          end
        end
      end

      module ClassMethods
        def sprockets_options
          opts[:sprockets]
        end

        def sprockets_regexp
          %r{#{::Sprockets::Helpers.prefix[1..-1]}/(.*)}
        end
      end

      module InstanceMethods
        include ::Sprockets::Helpers

        def sprockets_options
          self.class.sprockets_options
        end
      end

      module RequestMethods
        def sprockets
          get self.roda_class.sprockets_regexp do |path|
            options                    = scope.sprockets_options
            env_sprockets              = scope.request.env.dup
            env_sprockets['PATH_INFO'] = path

            status, headers, response = options[:sprockets].call env_sprockets

            # Appease Rack::Lint
            if (300..399).include? status
              headers.delete("Content-Type")
            end

            scope.response.status = status
            scope.response.headers.merge! headers

            response.is_a?(Array) ? response.join('\n') : response.to_s
          end
        end
      end
    end

    register_plugin :sprockets, Sprockets
  end
end
