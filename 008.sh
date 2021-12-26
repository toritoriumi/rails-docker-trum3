# Docker超入門講座 合併版 | ゼロから実践する4時間のフルコース

# 事前準備

    $ cd tutorials/docker

    $ git config --global user.name "toritoriumi"
    $ git config --global user.email "spiegel@keio.jp"
    $ git config --global merge.ff false   # 意味を理解していない
    $ git config --global pull.rebase merges # 意味を理解していない

    $ git config --list  # 上記４つの設定を確認

    # ここで、herokuのアカウントを作っておく
    # herokuは、アプリ作成時に用いるインフラを提供してくれるサービス。ここでplugin利用のためにクレカ情報を
    # 登録した。

    # heroku cliをインストールし、コマンド上でherokuを使えるようにする。
    $ brew tap heroku/brew && brew install heroku

# herokuにログインする

    $ heroku login

    # heroku container registryにログインし、dockerのimageをアップできるようにする。
    $ heroku container:login

# herokuアプリを作成

    # アプリ名を作成する。重複すると作れないため注意。
    $ heroku create rails-docker-trum

# DBの追加・設定

    # DBは、herokuアプリにアドオンする形で追加。cleardbのignite というプランだけ無料らしい。
    # mysqlのversionが5系なので、localのmysqlを5系に揃えたほうが良い。今回はそのまま(local: 8系)
    $ heroku addons:create cleardb:ignite -a rails-docker-trum

    # rails, DBの接続先を変える
    # productionのDBの接続情報を環境変数に変える。環境ごとに接続先を変えられるようになる。
    # ソースコード公開時に、環境変数を用いることでパスワード等の情報を隠し、DCへの不正侵入を防ぐことができる。

    # src/config/database.ymlを開く。
    # production:を以下に変更する。
    # <<: *default
    # database: <%= ENV['APP_DATABASE'] %>
    # username: <%= ENV['APP_DATABASE_USERNAME'] %>
    # host: <%= ENV['APP_DATABASE_HOST'] %>
        # 後から気づいたが、passwordに関するものがない。気づいたときに追加した。

    # ターミナルで以下のコマンドを入力し、確認。
    $ heroku config -a rails-docker-trum
    
    # 以下が出力される。
    # CLEARDB_DATABASE_URL: mysql://(ユーザー名):(パスワード)@(ホスト名)/(DB名)?reconnect=true
    # ユーザー名、パスワード、ホスト名、DB名はメモすること。
    # heroku config:add コマンドで環境変数の値を設定できる。以下をターミナルで入力する。
    $ heroku config:add APP_DATABASE='heroku_2fadb7b465a1ebe' -a rails-docker-trum
    $ heroku config:add APP_DATABASE_USERNAME='b3e293908043ca' -a rails-docker-trum
    $ heroku config:add APP_DATABASE_PASSWORD='006a57f2' -a rails-docker-trum
    $ heroku config:add APP_DATABASE_HOST='us-cdbr-east-05.cleardb.net' -a rails-docker-trum

    # 以下のコマンドで、接続情報が正しく入力されたことを確認する。
    $ heroku config -a rails-docker-trum

        # 以下のように出力される。
        # === rails-docker-trum Config Vars
        # APP_DATABASE:          heroku_1cd2f36a9a74f0e
        # APP_DATABASE_HOST:     us-cdbr-east-05.cleardb.net
        # APP_DATABASE_PASSWORD: c926c21c
        # APP_DATABASE_USERNAME: bf028d40022ea6
        # CLEARDB_DATABASE_URL:  mysql://bf028d40022ea6:c926c21c@us-cdbr-east-05.cleardb.net/heroku_1cd2f36a9a74f0e?reconnect=true


# Dockerfileを本番環境用に修正

    # 本番環境でのみ実行させたい操作がある(bundle exec rails assets:precompile)
    # そのため、Dockerfileを一部変更し、start.shを作成。
    # そもそも本番とlocalでDockerfileを分けてしまっても良い。

    # 環境変数を追加する。assets:precompileを起動させるための操作
    $ heroku config:add RAILS_SERVE_STATIC_FILES='true' -a rails-docker-trum

    # 設定を変える。tools.heroku.support/limits/boot_timeout に行く。
    # herokuの無料版のマシンパワーが弱いため、受付時間を60秒から120秒にする。不要なエラーを減らす。

    # localのサーバーとherokuのサーバーの設定がconflictする場合があるので、以下の操作をする。
    $ docker-compose down
    $ rm src/tmp/pids/server.pid

    # 準備完了

# Docker イメージをビルド・リリース

    # Docker imageをBuildし、container registryにpushする。
    $ heroku container:push web -a rails-docker-trum

    # container resitryにあげたimageから、herokuにDocker containerをリリースする。
    # 初回実行時非常に時間がかかる。(~20分?)
    $ heroku container:release web -a rails-docker-trum

    # 通常のflowだと、DBの更新をする(migration?)
    # DBのtableを書いてあるように作ってくれる。 (??????)
    $ heroku run bundle exec rake db:migrate RAILS_ENV=production -a rails-docker-trum

    # herokuのアプリを開く
    $ heroku open -a rails-docker-trum

    # "Heroku | Welcome to your new app!" と表示された。
    # エラーになったら、ググって解決。動画を見るだけにして諦めるのもあり。
    # logの表示を以下で変更し、エラー時の対処をしやすくする。
    $ heroku config:add RAILS_LOG_TO_STDOUT='true' -a rails-docker-trum
    $ heroku logs -t -a rails-docker-trum

    # ^Cで終了。

# 機能追加
    # top pageにアクセスしたら、htmlが表示されるようにする。
    # dockerのコントローラーを作る(??)
    # コントローラー: ブラウザからのリクエストを受け取る部分。

    $ docker-compose up -d
    $ docker-compose exec web bundle exec rails g controller users

    # 以下のように出力される。
    # Running via Spring preloader in process 43
    #  create  app/controllers/users_controller.rb
    #  invoke  erb
    #  create    app/views/users
    #  invoke  test_unit
    #  create    test/controllers/users_controller_test.rb
    #  invoke  helper
    #  create    app/helpers/users_helper.rb
    #  invoke    test_unit
    #  invoke  assets
    #  invoke    scss
    #  create      app/assets/stylesheets/users.scss

    # config/routes.rbを開く。
    # どのurlに来たら、どのコントローラーのどのアクションにリクエストを送るのか、ということを設定する。
    # 以下のように変更する。

    # Rails.application.routes.draw do
    #  For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
    # get '/', to: 'users#index'
    # end

    # users#indexに通信が行くようになった。
    # 次に、app/controllers から、users_controller.rbを編集し、以下のようにする。

    # class UsersController < ApplicationController
    #   def index
    #   end      
    # end

    # 次に、htmlファイルを表示できるように、viewファイル(?)を作成する。
    # app/views/users に、index.html.erb を作成する。

    # index.html.erbの中身　-> <h1>Hello world!</h1>

    # ブラウザで、localhost:3000と検索。Hello world!が表示される。

    #これをlocalではなくherokuで実行する。
    # まず、現在開いているdockerを閉じる。
    $ docker-compose down
    $ rm src/tmp/pids/server.pid

    # container作成、リリース、openまでを実行。
    $ heroku container:push web -a rails-docker-trum
    $ heroku container:release web -a rails-docker-trum
    $ heroku open

    # 進まない。以下のようなエラーを吐かれる。

    # 2021-12-24T21:15:14.200454+00:00 heroku[router]: at=error code=H10 
    # desc="App crashed" method=GET path="/favicon.ico" host=rails-docker-trum.herokuapp.com 
    # request_id=ba5afa96-02ed-4be4-85c4-7a7e53acde64 fwd="133.200.52.160" 
    # dyno= connect= service= status=503 bytes= protocol=https

    # どうしようもないので、007からやり直す。



# 007
    # Dockerfile, docker-compose.yml, src/ を作成
    # src/には、Gemfileを作成。以下はその中身
    # $ source 'https://rubygems.org'
    # $ gem 'rails', '~> 6.1.0'

    # railsの雛形をダウンロード
    $ docker-compose run web rails new . --force --database=mysql

    # ここで、src/以下にファイル、ディレクトリが新たに作成されていることを確認。

    # imageをbuild
    $ docker-compose build

    # DBの設定をする
    # src/config/database.yml を開き、defaultの記述欄を確認。
    # passwordに、"password" と入力。
    # host(接続先)に、"db" を入力。

    # DBを作成する。
    $ docker-compose run web rails db:create

    # dockerの起動
    $ docker-compose up

    # サーバーの起動を確認する。
    # ブラウザで、localhost:3000 と入力。

    # 追加の機能

        # サーバーの停止、削除まで行う。
        $ docker-compose down

        # 再度起動。また、バックグラウンドで起動したい。
        $ docker-compose up -d

        # コンテナ一覧表示
        $ docker-compose ps

        # ログを見る
        $ docker-compose logs

        # コンテナ内でコマンドを実行するとき
        $ docker-compose exec
            # 例： decker-compose exec web /bin/bash    exitで抜ける

    # エラーの原因らしきもの:
    # src/tmp/pids/server.pid というファイルが残っていた。このファイルを削除すると、
    # localhost:3000 を検索時、You are on Rails! と表示された。
    # 008の作業に戻る。

    # やはり同様のエラーを吐かれる。
    # 2021-12-25T08:57:17.238309+00:00 heroku[router]: at=error code=H10 desc="App crashed" 
    # method=GET path="/favicon.ico" host=rails-docker-trum.herokuapp.com 
    # request_id=c9359731-3055-48f4-ad14-b058586c2ba3 fwd="133.200.52.160" 
    # dyno= connect= service= status=503 bytes= protocol=https

    # appを一度削除知てみる。以下のコードを実行した。
    $ heroku apps:destroy --app rails-docker-trum --confirm rails-docker-trum


    # もう一度appの作成からやってみる。

    # だめだった。同様のエラーを吐かれる。
    # DB関連の異常が多いらしいのでdatabase.ymlのproductionで環境変数の使用をやめてみる(databaseのみ)。
    # production:
    #    <<: *default
    #    database: app_production
    #    username: <%= ENV['APP_DATABASE_USERNAME'] %> 
    #    password: <%= ENV['APP_DATABASE_PASSWORD'] %>
    #    host: <%= ENV['APP_DATABASE_HOST'] %>








    # 以下を実行。

    $ heroku apps:destroy --app rails-docker-trum3 --confirm rails-docker-trum3
    $ heroku create rails-docker-trum3
    $ heroku addons:create cleardb:ignite -a rails-docker-trum3
    $ heroku config -a rails-docker-trum3


    # CLEARDB_DATABASE_URL: mysql://(ユーザー名):(パスワード)@(ホスト名)/(DB名)?reconnect=true
    $ heroku config:add APP_DATABASE='heroku_84319568a73ac21' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_USERNAME='bad54d63bd038b' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_PASSWORD='486479f1' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_HOST='us-cdbr-east-05.cleardb.net' -a rails-docker-trum3

    $ heroku config:add RAILS_SERVE_STATIC_FILES='true' -a rails-docker-trum3

    $ docker-compose down
    $ rm src/tmp/pids/server.pid

    $ heroku container:push web -a rails-docker-trum3
    $ heroku container:release web -a rails-docker-trum3

    $ heroku run bundle exec rake db:migrate RAILS_ENV=production -a rails-docker-trum3



    $ heroku open -a rails-docker-trum2

    # どうしようもないので諦めた。211225



    # 009についてはやることにする。

# -------------211216 ------------------------------------------------------------

    # docker自体をアンインストール、再インストールしてもう一度上記コードを実行。

    # heroku container:pushまで実行できた。
    # ここでエラー
    # "no basic auth credentials docker"

    # docker, heroku cliともに再度インストールした。

    #もう一度実行。おそらく先程のエラーはheroku container:loginを行っていなかったためと思われる。



    $ brew tap heroku/brew && brew install heroku
    $ heroku login
    $ heroku container:login
    $ heroku apps:destroy --app rails-docker-trum3 --confirm rails-docker-trum3
    $ heroku create rails-docker-trum3
    $ heroku addons:create cleardb:ignite -a rails-docker-trum3
    $ heroku config -a rails-docker-trum3


    # CLEARDB_DATABASE_URL: mysql://(ユーザー名):(パスワード)@(ホスト名)/(DB名)?reconnect=true
    $ heroku config:add APP_DATABASE='heroku_84319568a73ac21' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_USERNAME='bad54d63bd038b' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_PASSWORD='486479f1' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_HOST='us-cdbr-east-05.cleardb.net' -a rails-docker-trum3

    $ heroku config:add RAILS_SERVE_STATIC_FILES='true' -a rails-docker-trum3

    $ docker-compose down
    $ rm src/tmp/pids/server.pid

    $ heroku container:push web -a rails-docker-trum3
    $ heroku container:release web -a rails-docker-trum3
    $ heroku run bundle exec rake db:migrate RAILS_ENV=production -a rails-docker-trum3
    # この時の標準出力: 
    # =production -a rails-docker-trum3
    # Running bundle exec rake db:migrate RAILS_ENV=production on ⬢ rails-docker-trum3... up, run.4658 (Free)

    $ heroku open -a rails-docker-trum3
    # うまく行った気がする。
    # ブラウザに以下のような表示あり。

    # (ロゴ)
    # There's nothing here, yet.
    # Build something amazing

    # logの表示を以下で変更し、エラー時の対処をしやすくする。
    $ heroku config:add RAILS_LOG_TO_STDOUT='true' -a rails-docker-trum3
    $ heroku logs -t -a rails-docker-trum 3

# 機能追加
    # top pageにアクセスしたら、htmlが表示されるようにする。
    # dockerのコントローラーを作る(??)
    # コントローラー: ブラウザからのリクエストを受け取る部分。

    $ docker-compose up -d
    $ docker-compose exec web bundle exec rails g controller users

    # config/routes.rbを開く。

    # どのurlに来たら、どのコントローラーのどのアクションにリクエストを送るのか、ということを設定する。
    # 以下のように変更する。

    # Rails.application.routes.draw do
    #  For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
    # get '/', to: 'users#index'
    # end

    # users#indexに通信が行くようになった。
    # 次に、app/controllers から、users_controller.rbを編集し、以下のようにする。

    # class UsersController < ApplicationController
    #   def index
    #   end      
    # end

    # 次に、htmlファイルを表示できるように、viewファイル(?)を作成する。
    # app/views/users に、index.html.erb を作成する。

    # index.html.erbの中身　-> <h1>Hello world!</h1>

    # ブラウザで、localhost:3000と検索。Hello world!が表示される。
    # 表示されなかった。が続けてみる。

    #これをlocalではなくherokuで実行する。
    # まず、現在開いているdockerを閉じる。
    $ docker-compose down
    $ rm src/tmp/pids/server.pid

    # container作成、リリース、openまでを実行。
    $ heroku container:push web -a rails-docker-trum3
    $ heroku container:release web -a rails-docker-trum3
    $ heroku open -a rails-docker-trum3


    # ここで再度エラー。
    # 2021-12-26T12:22:54.373293+00:00 heroku[router]: at=error code=H20 desc="App boot timeout" 
    # method=GET path="/" host=rails-docker-trum3.herokuapp.com 
    # request_id=db5f96e5-0c82-48c2-b117-50ddbce568c7 fwd="133.200.52.160" 
    # dyno= connect= service= status=503 bytes= protocol=https

    # 設定を変える。tools.heroku.support/limits/boot_timeout に行く。
    # herokuの無料版のマシンパワーが弱いため、受付時間を60秒から120秒にする。不要なエラーを減らす。

    # heroku openしたものの、H=10のエラー。
    # もう一度heroku cliを再インストール。
    # 以下をこの順序で実行。機能追加が行われている状態で行う。

    $ brew tap heroku/brew && brew install heroku
    $ heroku login
    $ heroku container:login
    $ heroku apps:destroy --app rails-docker-trum3 --confirm rails-docker-trum3
    $ heroku create rails-docker-trum3
    $ heroku addons:create cleardb:ignite -a rails-docker-trum3
    $ heroku config -a rails-docker-trum3


    # CLEARDB_DATABASE_URL: mysql://(ユーザー名):(パスワード)@(ホスト名)/(DB名)?reconnect=true
    $ heroku config:add APP_DATABASE='heroku_e73e62d73fa23ba' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_USERNAME='b960b202b71bc4' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_PASSWORD='e91ea125' -a rails-docker-trum3
    $ heroku config:add APP_DATABASE_HOST='us-cdbr-east-05.cleardb.net' -a rails-docker-trum3

    $ heroku config:add RAILS_SERVE_STATIC_FILES='true' -a rails-docker-trum3

    $ docker-compose down
    $ rm src/tmp/pids/server.pid

    $ heroku container:push web -a rails-docker-trum3
    $ heroku container:release web -a rails-docker-trum3
    $ heroku run bundle exec rake db:migrate RAILS_ENV=production -a rails-docker-trum3
    
    $ heroku open -a rails-docker-trum3
    
    # logの表示を以下で変更し、エラー時の対処をしやすくする。
    $ heroku config:add RAILS_LOG_TO_STDOUT='true' -a rails-docker-trum3
    $ heroku logs -t -a rails-docker-trum3


    # エラー発生。このまま009を行う。










