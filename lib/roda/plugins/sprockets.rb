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
        public_path:    "public/assets/",
        path_prefix:    "/assets",
        protocol:       :http,
        css_compressor: nil,
        js_compressor:  nil,
        host:           nil,
        digest:         true,
        opal:           false,
        debug:          false,
        cache:          nil,
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

        if !options[:root]
          options[:root] = app.opts[:root] || Dir.pwd
        end

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

        if options[:cache]
          options[:sprockets].cache = options[:cache]
        end

        options[:sprockets_helpers] = ::Sprockets::Helpers::Settings.new

        options[:sprockets_helpers].environment = options[:sprockets]
        options[:sprockets_helpers].digest      = options[:digest]
        options[:sprockets_helpers].prefix      = options[:path_prefix] unless options[:path_prefix].nil?
        options[:sprockets_helpers].debug       = options[:debug]

        app.configure :staging, :production do
          options[:sprockets].css_compressor = options[:css_compressor] unless options[:css_compressor].nil?
          options[:sprockets].js_compressor  = options[:js_compressor] unless options[:js_compressor].nil?

          options[:sprockets_helpers].manifest   = ::Sprockets::Manifest.new(options[:sprockets], options[:public_path])
          options[:sprockets_helpers].protocol   = options[:protocol]
          options[:sprockets_helpers].asset_host = options[:host] unless options[:host].nil?
        end
      end

      module ClassMethods
        def sprockets_options
          opts[:sprockets]
        end

        def sprockets_regexp
          %r{#{sprockets_options[:sprockets_helpers].prefix[1..-1]}/(.*)}
        end
      end

      module InstanceMethods
        include ::Sprockets::Helpers

        def sprockets_options
          self.class.sprockets_options
        end

        # Overload of Sprockets::Helpers#sprockets_helpers_settings to support polyinstantiation
        def sprockets_helpers_settings
          sprockets_options[:sprockets_helpers]
        end

        # Require Opal assets
        def opal_require file
          <<~END
            <script>
              Opal.loaded(typeof(OpalLoaded) === "undefined" ? [] : OpalLoaded);
              Opal.require(#{file.to_json});
            </script>
          END
          .gsub(/\s+/, ' ').chop
        end
      end

      module RequestMethods
        def sprockets
          get self.roda_class.sprockets_regexp do |path|
            options                    = scope.sprockets_options
            env_sprockets              = scope.request.env.dup
            env_sprockets['PATH_INFO'] = path

            status, headers, response = options[:sprockets].call env_sprockets

            scope.response.status = status
            scope.response.headers.merge! headers

            case response
            when nil, []
              # Empty response happens for example when 304 Not Modified happens.
              # We want to return nil in this case.
              # (See: https://github.com/hmdne/roda-sprockets/issues/1)
              nil
            when Array
              response.join("\n")
            else
              response.to_s
            end
          end
        end
      end
    end

    register_plugin :sprockets, Sprockets
  end
end
