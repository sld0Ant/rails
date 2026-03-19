# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      module EndpointResources
        # Generates RESTful routes for a declarative Endpoint class.
        #
        #   # config/routes.rb
        #   endpoint PostsEndpoint
        #   endpoint PostsEndpoint, only: [:index, :show]
        #   endpoint PostsEndpoint, except: [:destroy]
        #   endpoint PostsEndpoint, path: "articles"
        #
        def endpoint(endpoint_class, only: nil, except: nil, path: nil)
          resource_name = endpoint_class.resource_name
          path ||= resource_name.to_s.pluralize

          actions = %i[index show create update destroy]
          actions &= Array(only) if only
          actions -= Array(except) if except

          scope path, format: :json do
            get    "/",    to: endpoint_dispatch(endpoint_class, :index),   as: path              if actions.include?(:index)
            post   "/",    to: endpoint_dispatch(endpoint_class, :create)                         if actions.include?(:create)
            get    "/:id", to: endpoint_dispatch(endpoint_class, :show),    as: resource_name     if actions.include?(:show)
            patch  "/:id", to: endpoint_dispatch(endpoint_class, :update)                         if actions.include?(:update)
            put    "/:id", to: endpoint_dispatch(endpoint_class, :update)                         if actions.include?(:update)
            delete "/:id", to: endpoint_dispatch(endpoint_class, :destroy)                        if actions.include?(:destroy)
          end
        end

        private

        def endpoint_dispatch(endpoint_class, action_name)
          lambda do |env|
            request = ActionDispatch::Request.new(env)
            path_params = env["action_dispatch.request.path_parameters"] || {}
            request_params = begin
              request.request_parameters
            rescue StandardError
              {}
            end
            query_params = begin
              request.query_parameters
            rescue StandardError
              {}
            end

            params = query_params
              .merge(request_params)
              .merge(path_params)
              .with_indifferent_access

            endpoint_class.new.public_send(action_name, params)
          end
        end
      end
    end
  end
end
