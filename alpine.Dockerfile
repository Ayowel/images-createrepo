ARG BUILD_IMAGE=alpine
ARG TARGET_IMAGE=$BUILD_IMAGE

FROM $BUILD_IMAGE as build
ARG LANG=C.UTF-8
ARG GIT_SOURCE_REPO="https://github.com/rpm-software-management/createrepo_c.git"
ARG GIT_SOURCE_COMMIT=master
ARG GIT_ZCHUNK_REPO="https://github.com/zchunk/zchunk.git"
ARG GIT_ZCHUNK_COMMIT=main
ARG GIT_MODULEMD_REPO="https://github.com/fedora-modularity/libmodulemd.git"
ARG GIT_MODULEMD_COMMIT=main
# Install build dependencies
RUN apk update \
    && apk add git make cmake gcc python3 py3-pip bash-completion \
    && apk add bzip2-dev curl-dev libxml2-dev openssl-dev sqlite-dev rpm-dev glib-dev file-dev python3-dev musl-dev \
    && git clone --depth 1 -b "$GIT_ZCHUNK_COMMIT" "$GIT_ZCHUNK_REPO" /opt/zchunk \
    && apk add meson ninja argp-standalone \
    && cd /opt/zchunk \
    && meson build \
    && cd build \
    && ninja \
    && ninja test \
    && ninja install \
    && git clone --depth 1 -b "$GIT_MODULEMD_COMMIT" "$GIT_MODULEMD_REPO" /opt/modulemd \
    && apk add yaml-dev cairo-dev gobject-introspection-dev \
    && pip install black pycodestyle PyGObject \
    && cd /opt/modulemd \
    && meson -Ddeveloper_build=false -Dskip_introspection=true -Dwith_docs=false -Dwith_manpages=disabled build \
    && cd build \
    && ninja \
    && ninja install
# Run createrepo build
RUN git clone --depth 1 -b "$GIT_SOURCE_COMMIT" "$GIT_SOURCE_REPO" /opt/createrepo \
    && mkdir /opt/createrepo_build \
    && cd /opt/createrepo_build \
    && cmake -DCREATEREPO_C_INSTALL_DEVELOPMENT=OFF -DCREATEREPO_C_INSTALL_MANPAGES=OFF -Wno-dev ../createrepo \
    && make \
    && ln -sf /usr/local/lib/ /usr/local/lib64 \
    && make install

FROM $TARGET_IMAGE
COPY --from=build /usr/local/lib/libzck.so /usr/local/lib/libmodulemd.so /usr/local/lib64/libcreaterepo_c.so /usr/local/lib/
COPY --from=build /usr/local/bin/createrepo_c /usr/local/bin/mergerepo_c /usr/local/bin/modifyrepo_c /usr/local/bin/sqliterepo_c /usr/local/bin/
RUN apk add file glib libcurl libxml2 rpm sqlite yaml \
    && rm -rf /var/cache/apk/* \
    && ln -sf /usr/local/lib/libmodulemd.so /usr/local/lib/libmodulemd.so.2 \
    && ln -sf /usr/local/lib/libzck.so /usr/local/lib/libzck.so.1 \
    && ln -sf /usr/local/lib/libcreaterepo_c.so /usr/local/lib/libcreaterepo_c.so.0 \
    && ln -sf /usr/local/bin/createrepo_c /usr/local/bin/createrepo \
    && ln -sf /usr/local/bin/modifyrepo_c /usr/local/bin/modifyrepo \
    && ln -sf /usr/local/bin/mergerepo_c /usr/local/bin/mergerepo \
    && ln -sf /usr/local/bin/sqliterepo_c /usr/local/bin/sqliterepo
VOLUME ["/mnt"]
WORKDIR /mnt
CMD [ "createrepo", "--help" ]
