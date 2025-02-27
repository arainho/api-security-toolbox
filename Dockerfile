## DIGEST f0a9bdbceb34c8a3f4bf5455998c5f562e53e6d1f764bbdd2ac519a8c3ef2559
## docker.io/golang:alpine3.14

FROM docker.io/golang@sha256:f0a9bdbceb34c8a3f4bf5455998c5f562e53e6d1f764bbdd2ac519a8c3ef2559 AS build-env
LABEL org.opencontainers.image.authors="github.com/arainho"

ENV MY_USER="appuser"
ENV MY_GROUP="appgroup"
ENV MY_HOME="/home/$MY_USER"
ENV GOPATH="$MY_HOME/go"
ENV APPS_TARGET="$MY_HOME/apps"
ENV PATH="$MY_HOME/bin:$MY_HOME/go/bin:$MY_HOME/.local/bin:$HOME/node_modules/.bin:$HOME/.rbenv/bin:$PATH:$MY_HOME/.cargo/bin:$MY_HOME/.apicheck_manager/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# general
RUN addgroup -g 9999 $MY_GROUP && \
    adduser -u 9999 -D -G $MY_GROUP -h $MY_HOME $MY_USER && \
    apk update && \
    apk add --no-cache sudo && \
    adduser $MY_USER wheel && \
    echo "$MY_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$MY_USER && \
    chmod 0440 /etc/sudoers.d/$MY_USER && \
    apk add --no-cache bash zsh fish vim nano \
                       bind-tools openssh git strace gdb \
                       mandoc man-pages less less-doc jq \
                       netcat-openbsd curl wget httpie nmap \
                       ca-certificates coreutils libzip-dev zip unzip && \
    apk add --no-cache --update python2 python3 py3-pip && \
    python2 -m ensurepip && \
    unlink /usr/bin/pip && \
    unlink /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    python2 -m pip install --upgrade pip setuptools && \
    python3 -m pip install --upgrade pip setuptools && \
    apk add --no-cache --update nodejs npm && \
    apk add --no-cache --update libffi-dev python3-dev && \
    apk add --no-cache --update wireshark xxd protoc && \
        adduser $MY_USER wireshark && \
    apk add --no-cache --update perl && \
    apk add --no-cache --update ruby ruby-dev && \
    apk add --no-cache --update openssl openssl-dev openssl-libs-static  && \
    apk add --no-cache --update alpine-sdk clang gcc make build-base cmake && \
    apk add --no-cache --update bsd-compat-headers linux-headers && \
    apk add --no-cache --update zlib-dev libevent libevent-dev && \
    apk add --no-cache --update openjdk8-jre gradle && \
    apk add --no-cache --update bash icu-libs krb5-libs libgcc libintl libssl1.1 libstdc++ zlib && \
    apk add --no-cache ragel boost-dev pkgconfig libpcap-dev && \
    apk add --no-cache libgdiplus --repository https://dl-3.alpinelinux.org/alpine/edge/testing

USER $MY_USER
WORKDIR $MY_HOME

# create folders
RUN mkdir -m 750 -p $APPS_TARGET && \
    mkdir -m 750 -p $MY_HOME/bin && \
    mkdir -m 750 -p $MY_HOME/plugins && \
    mkdir -m 750 -p $MY_HOME/wordlists && \
    mkdir -m 750 -p $MY_HOME/extensions && \
    mkdir -m 750 -p $MY_HOME/templates && \
    mkdir -m 750 -p $MY_HOME/signatures && \
    mkdir -m 750 -p $MY_HOME/share/man/man1

# virtual envs, pkg's, versions managers and utilities
RUN python3 -m pip install --upgrade pipenv && \
    python3 -m pip install --user virtualenv && \
    python2 -m pip install --user virtualenv && \
    python3 -m pip install --user yq && \
    python3 -m pip install --user xq && \
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH" && \
    echo 'if which ruby >/dev/null && which gem >/dev/null; then PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"; fi' >> ~/.bashrc && \
    npm install yarn && \
    export PATH="$PATH:$($HOME/node_modules/.bin/yarn global bin)" && \
    echo 'if which yarn >/dev/null; then echo export PATH="$PATH:$($HOME/node_modules/.bin/yarn global bin)"; fi' >> ~/.bashrc && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source $MY_HOME/.cargo/env && \
    rustup component add rustfmt && \
    rustup component add clippy

# secrets
RUN go get -u -v github.com/eth0izzle/shhgit && \
        mkdir -p $MY_HOME/signatures/eth0izzle-signatures/ && \
        curl -o $MY_HOME/signatures/eth0izzle-signatures/config.yaml https://raw.githubusercontent.com/eth0izzle/shhgit/master/config.yaml && \
    pip3 install --user truffleHog && \
    GO111MODULE=on go get -v -u github.com/zricethezav/gitleaks/v7 && \
    pip3 install --user detect-secrets && \
    git clone --depth=1 https://github.com/awslabs/git-secrets.git $APPS_TARGET/git-secrets && \
        cd $APPS_TARGET/git-secrets && \
        PREFIX=$MY_HOME make install && \
    git clone --depth=1 https://github.com/auth0/repo-supervisor.git $APPS_TARGET/repo-supervisor && \
        cd $APPS_TARGET/repo-supervisor && \
        npm ci && \
        npm run build

# enumeration
RUN go install github.com/OJ/gobuster/v3@latest && \
    python3 -m pip install --user dirsearch && \
    go get -u -v github.com/dwisiswant0/wadl-dumper && \
    go get -u -v github.com/ffuf/ffuf && \
    git clone --depth=1 https://github.com/OWASP/Amass.git $APPS_TARGET/Amass && \
        cd $APPS_TARGET/Amass && \
        go install -v ./... && \
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest && \
        git clone --depth=1 https://github.com/projectdiscovery/nuclei-templates.git $MY_HOME/templates/nuclei-templates && \
    GO111MODULE=on go get -u -v github.com/jaeles-project/jaeles && \
        GO111MODULE=on go get -u github.com/jaeles-project/gospider && \
        git clone --depth=1 https://github.com/jaeles-project/jaeles-signatures.git $MY_HOME/signatures/jaeles-signatures && \
    python3 -m pip install --user --upgrade arjun && \
    git clone --depth=1 https://github.com/devanshbatham/ParamSpider $APPS_TARGET/ParamSpider && \
        cd $APPS_TARGET/ParamSpider && \
        python3 -m pip install --user -r requirements.txt && \
    git clone --depth=1 https://github.com/mseclab/PyJFuzz.git $APPS_TARGET/PyJFuzz && \
        cd $APPS_TARGET/PyJFuzz && \
        python3 setup.py install --prefix=$MY_HOME/.local && \
    git clone --depth=1 https://github.com/Teebytes/TnT-Fuzzer.git $APPS_TARGET/TnT-Fuzzer && \
        cd $APPS_TARGET/TnT-Fuzzer && \
        python3 setup.py install --prefix=$MY_HOME/.local && \
    git clone --depth=1 https://github.com/assetnote/kiterunner $APPS_TARGET/kiterunner && \
        cd $APPS_TARGET/kiterunner && \
        make build && \
        ln -s $(pwd)/dist/kr $MY_HOME/bin/kr && \
        ln -s $APPS_TARGET/kiterunner/api-signatures $MY_HOME/signatures/kiterunner-api-signatures

# burp extentions or utilities
RUN cd $MY_HOME/extensions && \
    git clone --depth=1 https://github.com/portswigger/wsdl-wizard && \
    git clone --depth=1 https://github.com/NetSPI/Wsdler && \
    git clone --depth=1  https://github.com/SecurityInnovation/AuthMatrix.git && \
    git clone --depth=1 https://github.com/PortSwigger/autorize.git && \
    git clone --depth=1 https://github.com/portswigger/auth-analyzer && \
    git clone --depth=1 https://github.com/doyensec/inql && \
    git clone --depth=1 https://github.com/wallarm/jwt-heartbreaker.git && \
    git clone --depth=1 https://github.com/PortSwigger/json-web-token-attacker.git && \
    pip3 install json2paths

# graphql
RUN npm install get-graphql-schema

# traffic analysis
RUN python3 -m pip install --user pipx && \
    pipx install mitmproxy && \
    cd $MY_HOME/plugins && \
        git clone --depth=1  https://github.com/128technology/protobuf_dissector.git

# android
RUN pip3 install --user apkleaks

# wayback machine
RUN go get -u -v github.com/tomnomnom/waybackurls && \
    GO111MODULE=on go get -u -v github.com/lc/gau

# other
RUN  git clone --depth=1 https://github.com/ant4g0nist/susanoo $APPS_TARGET/susanoo && \
        cd $APPS_TARGET/susanoo && \
        python2 -m pip install --user -r requirements.txt && \
    git clone --depth=1  https://github.com/flipkart-incubator/Astra $APPS_TARGET/Astra && \
        cd $APPS_TARGET/Astra && \
        python2 -m pip install --user -r requirements.txt && \
    go get -u -v github.com/bncrypted/apidor && \
    git clone --depth=1 https://gitlab.com/dee-see/graphql-path-enum $APPS_TARGET/graphql-path-enum && \
        cd $APPS_TARGET/graphql-path-enum && \
        cargo build && \
    git clone --recursive --depth=1 https://github.com/trailofbits/protofuzz.git $APPS_TARGET/protofuzz && \
        cd $APPS_TARGET/protofuzz && \
        python3 setup.py install --prefix=$MY_HOME/.local && \
    git clone --depth=1 https://github.com/ticarpi/jwt_tool $APPS_TARGET/jwt_tool && \
        cd $APPS_TARGET/jwt_tool && \
        python3 -m pip install --user termcolor cprint pycryptodomex requests && \
    npm install jwt-cracker && \
    git clone --depth=1 https://github.com/AresS31/jwtcat $APPS_TARGET/jwtcat && \
        cd $APPS_TARGET/jwtcat && \
        python3 -m pip install --user -r requirements.txt && \
    git clone --depth=1 https://github.com/silentsignal/rsa_sign2n $APPS_TARGET/rsa_sig2n && \
    python3 -m pip install --user jwtxploiter && \
    python3 -m pip install --user apicheck-package-manager && \
        mkdir -p $MY_HOME/.apicheck_manager/bin && \
        export PATH="$HOME/.apicheck_manager/bin:$PATH" && \
        #
        # next lines require that /var/run/docker.sock is mounted
        #acp install jwt-checker && \
        #acp install acurl && \
        #acp install oas-checker && \
        #acp install send-to-proxy && \
        #acp install apicheck-curl && \
        #acp install sensitive-data && \
        #acp install replay && \
        #acp install openapiv3-lint && \
        #acp install openapiv2-lint && \
        #acp install oas-checker && \
     python3 -m pip install --user regexploit

# build fail, skip for now
#RUN git clone --depth=1 https://github.com/racepwn/racepwn $APPS_TARGET/racepwn && \
#    cd $APPS_TARGET/racepwn && \
#    ./build.sh

RUN git clone --depth=1  https://github.com/TheHackerDev/race-the-web $MY_HOME/race-the-web && \
        curl -o $MY_HOME/bin/race-the-web_2.0.1_lin64.bin \
             -L https://github.com/TheHackerDev/race-the-web/releases/download/2.0.1/race-the-web_2.0.1_lin64.bin && \
        chmod u+x $MY_HOME/bin/race-the-web_2.0.1_lin64.bin
        
RUN gem install --user-install API_Fuzzer
RUN git clone --depth=1 https://github.com/szski/shapeshifter.git $APPS_TARGET/shapeshifter && \
        cd $APPS_TARGET/shapeshifter/shapeshifter && \
        python3 -m pip install --user .
RUN git clone --depth 1 https://github.com/drwetter/testssl.sh.git $APPS_TARGET/testssl.sh && \
        chmod +x $APPS_TARGET/testssl.sh/testssl.sh && \
        ln -s $APPS_TARGET/testssl.sh/testssl.sh $MY_HOME/bin/testssl.sh
RUN git clone --depth=1 https://github.com/assetnote/batchql.git $APPS_TARGET/batchql
RUN git clone --depth=1 https://github.com/swisskyrepo/GraphQLmap $APPS_TARGET/GraphQLmap
RUN git clone --depth=1 https://github.com/digininja/CeWL $APPS_TARGET/CeWL && \
        cd $APPS_TARGET/CeWL && \
        gem install --user-install bundler mime mime-types mini_exiftool nokogiri rubyzip spider && \
        chmod u+x ./cewl.rb && \
        ln -s $APPS_TARGET/CeWL/cewl.rb $MY_HOME/bin/cewl.rb
RUN git clone --depth=1 https://github.com/r3nt0n/bopscrk $APPS_TARGET/bopscrk && \
        cd $APPS_TARGET/bopscrk && \
        python3 -m pip install --user -r requirements.txt && \
    git clone --depth=1 https://github.com/imperva/automatic-api-attack-tool $APPS_TARGET/automatic-api-attack-tool && \
        cd $APPS_TARGET/automatic-api-attack-tool && \
        ./gradlew build && \
        cp -av src/main/resources/runnable.sh . && \
        cat runnable.sh ./build/libs/imperva-api-attack-tool.jar > api-attack.sh && \
        chmod +x api-attack.sh && \
        ln -s $APPS_TARGET/automatic-api-attack-tool/api-attack.sh $MY_HOME/bin/api-attack.sh && \
    git clone --depth=1 https://github.com/microsoft/restler-fuzzer $APPS_TARGET/restler-fuzzer && \
       curl -L -o $APPS_TARGET/restler-fuzzer/dotnet-install.sh https://dot.net/v1/dotnet-install.sh && \
       cd $APPS_TARGET/restler-fuzzer && \
       chmod u+x ./dotnet-install.sh && \
       ./dotnet-install.sh -c 5.0 && \
       export PATH="$HOME/.dotnet:$PATH" && \
       mkdir -p $APPS_TARGET/restler-fuzzer/restler_bin && \
       cd $APPS_TARGET/restler-fuzzer && \
       python3 -m pip install --user requests applicationinsights && \
       python3 ./build-restler.py --dest_dir $APPS_TARGET/restler-fuzzer/restler_bin && \
       ln -s $APPS_TARGET/restler-fuzzer/restler_bin/engine/restler.py $MY_HOME/bin/restler.py && \
    git clone --depth=1 https://github.com/ngalongc/openapi_security_scanner $APPS_TARGET/openapi_security_scanner && \
        cd $APPS_TARGET/openapi_security_scanner && \
        python3 -m pip install --user -r requirements.txt && \
        ln -s $APPS_TARGET/openapi_security_scanner/openapi_security_scanner.py  $MY_HOME/bin/openapi_security_scanner.py && \
    git clone --depth=1 https://github.com/nikitastupin/clairvoyance.git $APPS_TARGET/clairvoyance && \
        cd $APPS_TARGET/clairvoyance && \
        python3 -m pip install --user -r requirements.txt && \
        echo 'python3 -m clairvoyance __main__.py $@' > ~/bin/clairvoyance && \
        chmod u+x ~/bin/clairvoyance && \
    git clone --depth=1 https://github.com/dolevf/graphw00f.git $APPS_TARGET/graphw00f && \
        ln -s $APPS_TARGET/graphw00f/main.py $MY_HOME/bin/graphw00f.py && \
    python3 -m pip install --user fuzz-lightyear && \
    npm install newman && \
    python3 -m pip install --user --upgrade ciphey && \
    git clone --depth=1 https://github.com/rbsec/sslscan $APPS_TARGET/sslscan && \
        cd $APPS_TARGET/sslscan && \
        PREFIX=$MY_HOME make static && \
        PREFIX=$MY_HOME make install && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest  && \
    go install -v github.com/projectdiscovery/proxify/cmd/proxify@latest && \
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

# wordlists
RUN curl -o $MY_HOME/wordlists/common-api-endpoints-mazen160.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common-api-endpoints-mazen160.txt" && \
    curl -o $MY_HOME/wordlists/yassineaboukir-3203-common-api-endpoints.txt "https://gist.githubusercontent.com/yassineaboukir/8e12adefbd505ef704674ad6ad48743d/raw/3ea2b7175f2fcf8e6de835c72cb2b2048f73f847/List%2520of%2520API%2520endpoints%2520&%2520objects"  && \
    curl -o $MY_HOME/wordlists/danielmiessler-SecLists-swagger.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/swagger.txt" && \
    curl -o $MY_HOME/wordlists/danielmiessler-SecLists-api-endpoints.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/api/api-endpoints.txt" && \
    curl -o $MY_HOME/wordlists/danielmiessler-SecLists-graphql.txt "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/graphql.txt" && \
    curl -o $MY_HOME/wordlists/kiterunner-swagger-wordlist.txt "https://wordlists-cdn.assetnote.io/data/kiterunner/swagger-wordlist.txt" && \
    curl -o $MY_HOME/wordlists/httparchive_apiroutes_2021_08_28.txt "https://wordlists-cdn.assetnote.io/./data/automated/httparchive_apiroutes_2021_08_28.txt" && \
    curl -o $MY_HOME/wordlists/fuzzdb-project-common-methods.txt "https://github.com/fuzzdb-project/fuzzdb/tree/master/discovery/common-methods" && \
    curl -o $MY_HOME/wordlists/routes-large.kite.tar.gz "https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite.tar.gz" && \
    git clone --depth=1 https://github.com/chrislockard/api_wordlist.git $MY_HOME/wordlists/chrislockard && \
        cd $MY_HOME/wordlists && \ 
        tar xvzf routes-large.kite.tar.gz

# titanic wordlists repositories  (uncomment only if needed)
# RUN git clone --depth=1 https://github.com/danielmiessler/SecLists.git $MY_HOME/wordlists/danielmiessler-seclists && \      # (1.9G)
#     mkdir -p $MY_HOME/wordlists/assetnote-io && cd $MY_HOME/wordlists/assetnote-io && \                                     # (3.3G)
#         wget -r --no-parent -R "index.html*" https://wordlists-cdn.assetnote.io/data/ -nH && \
#     git clone --depth=1  https://github.com/assetnote/commonspeak2-wordlists.git $MY_HOME/wordlists/commonspeak2-wordlists  # (156M)

# exploit database repository (uncomment only if needed)
# RUN git clone --depth=1 https://github.com/offensive-security/exploitdb.git $MY_HOME/exploits                               # (331M)



# golang:alpine3.14
FROM golang@sha256:5ce2785c82a96349131913879a603fc44d9c10d438f61bba84ee6a1ef03f6c6f
LABEL org.opencontainers.image.authors="github.com/arainho"

ENV MY_USER="appuser"
ENV MY_GROUP="appgroup"
ENV MY_HOME="/home/$MY_USER"
ENV GOPATH="$MY_HOME/go"
ENV APPS_TARGET="$MY_HOME/apps"
ENV PATH="$MY_HOME/bin:$MY_HOME/go/bin:$MY_HOME/.local/bin:$HOME/node_modules/.bin:$HOME/.rbenv/bin:$PATH:$MY_HOME/.cargo/bin:$MY_HOME/.apicheck_manager/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN addgroup -g 9999 $MY_GROUP && \
    adduser -u 9999 -D -G $MY_GROUP -h $MY_HOME $MY_USER && \
    apk update && \
    apk add --no-cache sudo && \
    adduser $MY_USER wheel && \
    echo "$MY_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$MY_USER && \
    chmod 0440 /etc/sudoers.d/$MY_USER && \
    apk add --no-cache bash zsh fish \
                       bind-tools openssh git strace gdb \
                       mandoc man-pages less less-doc jq \
                       netcat-openbsd curl wget httpie nmap \
                       ca-certificates coreutils libzip-dev zip unzip && \
    apk add --no-cache --update python2 python3 py3-pip && \
    python2 -m ensurepip && \
    unlink /usr/bin/pip && \
    unlink /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    python2 -m pip install --upgrade pip setuptools && \
    python3 -m pip install --upgrade pip setuptools && \
    apk add --no-cache --update nodejs npm && \
    apk add --no-cache --update libffi-dev python3-dev && \
    apk add --no-cache --update wireshark xxd protoc && \
    apk add --no-cache --update perl && \
    apk add --no-cache --update ruby ruby-dev && \
    apk add --no-cache --update openssl openssl-dev openssl-libs-static  && \
    apk add --no-cache --update alpine-sdk clang gcc make build-base cmake && \
    apk add --no-cache --update bsd-compat-headers linux-headers && \
    apk add --no-cache --update zlib-dev libevent libevent-dev && \
    apk add --no-cache --update openjdk8-jre gradle && \
    apk add --no-cache --update bash icu-libs krb5-libs libgcc libintl libssl1.1 libstdc++ zlib && \
    apk add --no-cache --update ragel boost-dev pkgconfig libpcap-dev && \
    apk add --no-cache libgdiplus --repository https://dl-3.alpinelinux.org/alpine/edge/testing && \
    adduser $MY_USER wireshark

USER $MY_USER
WORKDIR $MY_HOME

# create folders
RUN mkdir -m 750 -p $APPS_TARGET && \
    mkdir -m 750 -p $MY_HOME/bin && \
    mkdir -m 750 -p $MY_HOME/plugins && \
    mkdir -m 750 -p $MY_HOME/wordlists && \
    mkdir -m 750 -p $MY_HOME/extensions && \
    mkdir -m 750 -p $MY_HOME/templates && \
    mkdir -m 750 -p $MY_HOME/signatures && \
    mkdir -m 750 -p $MY_HOME/share/man/man1

# virtual envs, pkg's and versions managers
RUN python3 -m pip install --upgrade pipenv && \
    python3 -m pip install --user virtualenv && \
    python2 -m pip install --user virtualenv && \
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH" && \
    echo 'if which ruby >/dev/null && which gem >/dev/null; then PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"; fi' >> ~/.bashrc && \
    npm install yarn && \
    export PATH="$PATH:$($HOME/node_modules/.bin/yarn global bin)" && \
    echo 'if which yarn >/dev/null; then echo export PATH="$PATH:$($HOME/node_modules/.bin/yarn global bin)"; fi' >> ~/.bashrc && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source $MY_HOME/.cargo/env && \
    rustup component add rustfmt && \
    rustup component add clippy

COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/.bashrc $MY_HOME/.bashrc
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/.local $MY_HOME/.local
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/go $MY_HOME/go
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/bin $MY_HOME/bin
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/plugins $MY_HOME/plugins
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/wordlists $MY_HOME/wordlists
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/extensions $MY_HOME/extensions
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/templates $MY_HOME/templates
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/signatures $MY_HOME/signatures
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $MY_HOME/node_modules $MY_HOME/node_modules
COPY --chown=$MY_USER:$MY_GROUP --from=build-env $APPS_TARGET $APPS_TARGET

COPY --from=build-env /usr/local /usr/local
COPY --from=build-env /usr/local/bin /usr/local/bin
COPY --from=build-env /usr/share/man /usr/share/man
COPY --from=build-env /etc/sudoers.d /etc/sudoers.d

CMD ["/bin/bash"]
