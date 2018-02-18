require 'carrierwave'
require 'tencent_cloud_cos' # use qcloud cos SDK

module CarrierWave
  module Storage
    ##
    #  qcloud storage engine
    #
    #  CarrierWave.configure do |config|
    #    config.storage           = :qcloud
    #    config.qcloud_app_id     = 'xxxxxx'
    #    config.qcloud_secret_id  = 'xxxxxx'
    #    config.qcloud_secret_key = 'xxxxxx'
    #    config.qcloud_bucket     = "bucketname"
    #  end
    #
    # wiki: https://github.com/richardkmichael/carrierwave-activerecord/wiki/Howto:-Adding-a-new-storage-engine
    # rdoc: http://www.rubydoc.info/gems/carrierwave/CarrierWave/Storage/Abstract
    class Qcloud < Abstract
      # config qcloud sdk by getting configuration from uplander
      def self.configure_qcloud_sdk(uploader)
        TencentCloudCos.configure do |config|
          config.app_id     = uploader.qcloud_app_id
          config.secret_id  = uploader.qcloud_secret_id
          config.secret_key = uploader.qcloud_secret_key
          config.host       = uploader.qcloud_bucket_host
          config.content_type = uploader.content_type
        end
      end

      # hook: store the file on qcloud
      def store!(file)
        self.class.configure_qcloud_sdk(uploader)

        qcloud_file = File.new(file)
        qcloud_file.path = uploader.store_path(identifier)
        qcloud_file.store
        qcloud_file
      end

      # hook: retrieve the file on qcloud
      def retrieve!(identifier)
        self.class.configure_qcloud_sdk(uploader)

        if uploader.file # file is present after store!
          uploader.file
        else
          file_path = uploader.store_path(identifier)
          File.new(nil).tap do |file|
            file.path = file_path
            file.stat
          end
        end
      end

      # store and retrieve file using qcloud-cos-sdk
      # sdk ref: https://github.com/zlx/qcloud-cos-sdk/blob/master/wiki/get_started.md#api%E8%AF%A6%E7%BB%86%E8%AF%B4%E6%98%8E
      class File < CarrierWave::SanitizedFile
        attr_accessor :qcloud_info
        attr_accessor :path

        # store/upload file to qcloud
        def store
          result = TencentCloudCos.put(file.to_file, path)
          return result.code == 200
        end

        # file access url on qcloud
        def url
          TencentCloudCos.config.host + path
        end

        # get file stat on qcloud
        def stat
          # result = TencentCloudCos.stat(path)

        end

        # delete file on qcloud
        def delete
          result = TencentCloudCos.delete(path)
          result.code == 204
          # TODO: delete parent dir if it's empty
          # ref: https://github.com/carrierwaveuploader/carrierwave/wiki/How-to%3A-Make-a-fast-lookup-able-storage-directory-structure
        end

        # TODO: retrieve/download file from qcloud
        def retrieve
          # TODO
        end
      end

    end
  end
end
