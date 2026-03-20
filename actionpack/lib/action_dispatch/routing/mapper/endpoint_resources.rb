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

            entity_class = resource_name.to_s.camelize.constantize rescue nil
            if entity_class&.respond_to?(:transitions_config)
              entity_class.transitions_config.each_key do |t_name|
                post "/:id/#{t_name}", to: endpoint_dispatch(endpoint_class, :transition, context: { transition: t_name })
              end
            end

            if endpoint_class.respond_to?(:actions_config) && endpoint_class.actions_config.any?
              endpoint_class.actions_config.each do |action_cfg|
                method_sym = action_cfg[:method].to_s.downcase.to_sym
                name = action_cfg[:name].to_s
                if action_cfg[:on].to_s == "member"
                  send(method_sym, "/:id/#{name}", to: endpoint_dispatch(endpoint_class, :custom_action, context: { custom_action: name }))
                else
                  send(method_sym, "/#{name}", to: endpoint_dispatch(endpoint_class, :custom_action, context: { custom_action: name }))
                end
              end
            end
          end
        end

        private

        def check_authorization(endpoint_class, action_name, env)
          config = endpoint_class.respond_to?(:authorize_config) ? endpoint_class.authorize_config : {}
          return nil if config.empty?

          rule = config[action_name]
          return nil unless rule

          allowed = case rule
            when Array then rule
            when Hash  then Array(rule[:roles])
            else return nil
          end

          return nil if allowed.map(&:to_s).include?("*")

          role = env["HTTP_X_USER_ROLE"].to_s
          return nil if allowed.map(&:to_s).include?(role)

          [403, { "content-type" => "application/json" }, [{ "error" => "Forbidden", "status" => 403 }.to_json]]
        end

        def endpoint_dispatch(endpoint_class, action_name, context: {})
          transition = context[:transition]
          custom_action = context[:custom_action]

          lambda do |env|
            auth_key = custom_action || transition || action_name
            forbidden = check_authorization(endpoint_class, auth_key, env)
            return forbidden if forbidden

            label = if custom_action
              "custom_action.#{custom_action}"
            elsif transition
              "transition.#{transition}"
            else
              action_name.to_s
            end

            ActiveSupport::Notifications.instrument("endpoint.process",
              endpoint: endpoint_class.name, action: label) do

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

              if custom_action
                endpoint_class.new.custom_action(params, custom_action)
              elsif transition
                endpoint_class.new.transition(params, transition)
              else
                endpoint_class.new.public_send(action_name, params)
              end
            end
          rescue ActiveRecord::RecordNotFound
            [404, { "content-type" => "application/json" }, [{ "error" => "Not found", "status" => 404 }.to_json]]
          rescue StandardError => e
            Rails.error.report(e, handled: true) if defined?(Rails.error) && Rails.error.respond_to?(:report)
            [500, { "content-type" => "application/json" }, [{ "error" => e.message, "status" => 500 }.to_json]]
          end
        end
      end
    end
  end
end
