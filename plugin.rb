# name: discourse-buildzoom
# about: custom changes for BuildZoom
# version: 0.1
# authors: BuildZoom, David Lee
# url: https://github.com/buildzoom/discourse-buildzoom

PLUGIN_NAME = "discourse-buildzoom".freeze

after_initialize do
  module ::DiscourseBuildzoom
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseBuildzoom
    end
  end

  require_dependency 'permalink_constraint'
  class ::PermalinkConstraint
    def matches?(request)
      true
    end
  end

  require_dependency 'permalinks_controller'
  class ::PermalinksController < ApplicationController
    def show
      url = request.path
      permalink = Permalink.find_by_url(url)

      if permalink.nil? && !request.path.match('answers/').nil?
        topic_id = request.path.split('/')[2]
        permalink = Permalink.where("url like ?", "%/#{topic_id}/%").first
      end
      raise Discourse::NotFound unless permalink

      if permalink.external_url
        redirect_to permalink.external_url, status: :moved_permanently
      elsif permalink.target_url
        redirect_to permalink.target_url, status: :moved_permanently
      else
        raise Discourse::NotFound
      end
    end
  end

  require_dependency 'email/sender'
	class ::Email::Sender
		module DiscourseBuildzoomSend
			def send
				# set header for ESP analytics
				case ActionMailer::Base.smtp_settings[:address]
				when "smtp.mailgun.org"
					@message.header['X-Mailgun-Tag'] = @email_type.to_s
				end
				super
			end
		end
		prepend DiscourseBuildzoomSend
	end
end
