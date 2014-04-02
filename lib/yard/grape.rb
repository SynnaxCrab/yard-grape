require "yard"

module YARD

  module Grape
    def self.routes
      YARD::Handlers::Grape::AbstractRouteHandler.routes
    end

    def self.error_handlers
      YARD::Handlers::Grape::AbstractRouteHandler.error_handlers
    end
  end

  module CodeObjects
    class RouteObject < MethodObject
      attr_accessor :http_verb, :http_path, :real_name

      def name(prefix = false)
        return super unless show_real_name?
        prefix ? (sep == ISEP ? "#{sep}#{real_name}" : real_name.to_s) : real_name.to_sym
      end

      # @see YARD::Handlers::Grape::AbstractRouteHandler#register_route
      # @see #name
      def show_real_name?
        real_name and caller[1] =~ /`signature'/
      end

      def type
        :method
      end
    end
  end

  module Handlers

    # Displays Grape routes in YARD documentation.
    # Can also be used to parse routes from files without executing those files.
    module Grape
      # Logic both handlers have in common.
      module AbstractRouteHandler
        def self.uri_prefix
          uri_prefixes.join('')
        end

        def self.uri_prefixes
          @prefixes ||= []
        end

        def self.routes
          @routes ||= []
        end

        def self.error_handlers
          @error_handlers ||= []
        end

        def process
          case http_verb
          when 'NOT_FOUND'
            register_error_handler(http_verb)
          else
            path = http_path
            path = $1 if path =~ /^"(.*)"$/
            register_route(http_verb, path)
          end
        end

        def register_route(verb, path, doc = nil)
          # HACK: Removing some illegal letters.
          method_name = "" << verb << "_" << path.gsub(/[^\w_]/, "_")
          real_name   = "" << verb << " " << path
          route = register CodeObjects::RouteObject.new(namespace, method_name, :instance) do |o|
            o.visibility = "public"
            o.source     = statement.source
            o.signature  = real_name
            o.explicit   = true
            o.scope      = scope
            o.docstring  = statement.comments
            o.http_verb  = verb
            o.http_path  = path
            o.real_name  = real_name
            o.add_file(parser.file, statement.line)
          end
          AbstractRouteHandler.routes << route
          yield(route) if block_given?
        end

        def register_error_handler(verb, doc = nil)
          error_handler = register CodeObjects::RouteObject.new(namespace, verb, :instance) do |o|
            o.visibility = "public"
            o.source     = statement.source
            o.signature  = verb
            o.explicit   = true
            o.scope      = scope
            o.docstring  = statement.comments
            o.http_verb  = verb
            o.real_name  = verb
            o.add_file(parser.file, statement.line)
          end
          AbstractRouteHandler.error_handlers << error_handler
          yield(error_handler) if block_given?
        end
      end

      class ResourceHandler < YARD::Handlers::Ruby::Base
        handles method_call(:resource)
        namespace_only

        def process
          name = statement.parameters.first.jump(:tstring_content, :ident).source.capitalize
          object = YARD::CodeObjects::ClassObject.new(namespace, name)
          register(object)
          if object.tags(:real_name).any?
            object.name = object.tags(:real_name).first.text
            object.path = [object.namespace, object.name].join('::')
          end
          p statement.last.last
          parse_block(statement.last.last, :namespace => object)
          register(object)
        end
      end

      # Route handler for YARD's source parser.
      class RouteHandler < Ruby::Base
        include AbstractRouteHandler

        handles method_call(:get)
        handles method_call(:post)
        handles method_call(:put)
        handles method_call(:delete)
        handles method_call(:head)
        handles method_call(:not_found)

        def http_verb
          statement.method_name(true).to_s.upcase
        end

        def http_path
          statement.parameters.first.source
        end
      end

    end
  end
end
