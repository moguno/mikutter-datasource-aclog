#coding: utf-8

Plugin.create(:"mikutter-datasource-aclog") {
  require "yaml"

  counters = {}

  # 起動時処理
  on_boot { |service|
    Service.each { |s|
      counters[s] = gen_counter
    }
  }

  # 定期的にイベントを発生させる
  on_period { |service|
    count = counters[service].call

    if true || count >= UserConfig[:retrieve_interval_search]
      counters[service] = gen_counter

      Thread.new {
        refresh(service.user_obj)
      }
    end
  }

  # aclogからメッセージを取得してデータソースに流す
  def refresh(user)
    begin
      url = "http://aclog.koba789.com/api/tweets/user_timeline.yaml?screen_name=#{user[:idname]}"

      data = open(url) { |fp|
        YAML.load(fp.read)
      }

      data.each { |omoshiro_tweet|
        ((Service.primary.twitter/"statuses/show/#{omoshiro_tweet["id"]}").message).next { |res|
          Plugin.call(:extract_receive_message, :"aclog_#{user[:idname]}", Messages.new([res]))
        }
      }
    rescue => e
      puts e
      puts e.backtrace
    end
  end

  # 抽出タブ一覧
  filter_extract_datasources { |datasources|
    Service.each { |service|
      datasources[:"aclog_#{service.user_obj[:idname]}"] = "aclog/#{service.user_obj[:name]}"
    }

    [datasources]
  }
}
