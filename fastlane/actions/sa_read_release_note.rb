module Fastlane
  module Actions

    class SaReadReleaseNoteAction < Action
      def self.replace(filepath, regexp, *args, &block)
        content = File.read(filepath).gsub(regexp, *args, &block)
        File.open(filepath, 'wb') { |file| file.write(content) }
      end
      
      def self.run(params)
        file = File.new("#{params[:file_path]}", "r")
        if file
          content = file.sysread(1000)
          UI.success("#{params[:file_path]} content: \n #{content} \n")
          return content.force_encoding('UTF-8')
        else
          raise "No ReleaseNote found in #{params[:file_path]}".red
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Read release note form a file"
      end

      def self.details
        "Read release note form a file."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       description: "Path for the file",
                                       is_string: true,
                                       optional: false),
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ["minchaozhang"]
      end

      def self.is_supported?(platform)
        return true
      end
    end
  end
end
