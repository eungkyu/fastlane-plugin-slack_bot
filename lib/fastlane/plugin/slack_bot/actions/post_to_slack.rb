require 'fastlane/action'
require_relative '../helper/slack_bot_helper'

module Fastlane
  module Actions
    class PostToSlackAction < Action
      def self.run(params)
        require 'slack-notifier'

        options[:message] = (options[:message].to_s || '').gsub('\n', "\n")
        options[:message] = Slack::Notifier::Util::LinkFormatter.format(options[:message])

        options[:pretext] = options[:pretext].gsub('\n', "\n") unless options[:pretext].nil?

        if options[:channel].to_s.length > 0
          slack_channel = options[:channel]
          slack_channel = ('#' + options[:channel]) unless ['#', '@'].include?(slack_channel[0]) # send message to channel by default
        end

        slack_attachment = SlackAction.generate_slack_attachments(options)

        begin
          require 'excon'

          api_url = "https://slack.com/api/chat.postMessage"
          headers = { "Content-Type": "application/json", "Authorization": "Bearer #{options[:api_token]}" }
          payload = { channel: slack_channel, attachments: [slack_attachment] }.to_json

          Excon.post(api_url, headers: headers, body: payload)
        rescue => exception
          UI.error("Exception: #{exception}")
        else
          UI.success("Successfully sent Slack notification")
        end
      end

      def self.description
        "Post a slack message"
      end

      def self.details
        "Post a slack message to any #channel/@user using Slack bot chat postMessage api."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_POST_TO_SLACK_BOT_TOKEN",
                                       description: "Slack bot Token",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       is_string: true,
                                       default_value: ENV["SLACK_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "FL_POST_TO_SLACK_CHANNEL",
                                       description: "#channel or @username",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :pretext,
                                       env_name: "FL_POST_TO_SLACK_PRETEXT",
                                       description: "This is optional text that appears above the message attachment block. This supports the standard Slack markup language",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_POST_TO_SLACK_MESSAGE",
                                       description: "The message that should be displayed on Slack",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :payload,
                                       env_name: "FL_POST_TO_SLACK_PAYLOAD",
                                       description: "Add additional information to this post. payload must be a hash containing any key with any value",
                                       default_value: {},
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :default_payloads,
                                       env_name: "FL_POST_TO_SLACK_DEFAULT_PAYLOADS",
                                       description: "Remove some of the default payloads. More information about the available payloads on GitHub",
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :attachment_properties,
                                       env_name: "FL_POST_TO_SLACK_ATTACHMENT_PROPERTIES",
                                       description: "Merge additional properties in the slack attachment, see https://api.slack.com/docs/attachments",
                                       default_value: {},
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :success,
                                       env_name: "FL_POST_TO_SLACK_SUCCESS",
                                       description: "Was this successful? (true/false)",
                                       optional: true,
                                       default_value: true,
                                       is_string: false)
        ]
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'post_to_slack(message: "App successfully released!")',
          'post_to_slack(
            message: "App successfully released!",
            channel: "#channel",  # Optional, by default will post to the default channel configured for the POST URL.
            success: true,        # Optional, defaults to true.
            payload: {            # Optional, lets you specify any number of your own Slack attachments.
              "Build Date" => Time.new.to_s,
              "Built by" => "Jenkins",
            },
            default_payloads: [:git_branch, :git_author], # Optional, lets you specify a whitelist of default payloads to include. Pass an empty array to suppress all the default payloads.
                                                          # Don\'t add this key, or pass nil, if you want all the default payloads. The available default payloads are: `lane`, `test_result`, `git_branch`, `git_author`, `last_git_commit`, `last_git_commit_hash`.
            attachment_properties: { # Optional, lets you specify any other properties available for attachments in the slack API (see https://api.slack.com/docs/attachments).
                                     # This hash is deep merged with the existing properties set using the other properties above. This allows your own fields properties to be appended to the existing fields that were created using the `payload` property for instance.
              thumb_url: "http://example.com/path/to/thumb.png",
              fields: [{
                title: "My Field",
                value: "My Value",
                short: true
              }]
            }
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end