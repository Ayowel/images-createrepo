ARG BUILD_IMAGE=centos
ARG TARGET_IMAGE=$BUILD_IMAGE

FROM $BUILD_IMAGE as build
ARG LANG=C.UTF-8
ARG GIT_SOURCE_REPO="https://github.com/rpm-software-management/createrepo_c.git"
ARG GIT_SOURCE_COMMIT=master
RUN dnf install -y epel-release \
    && dnf install -y git make cmake gcc python3 bash-completion \
    && dnf install --enablerepo powertools -y bzip2-devel libcurl-devel libxml2-devel openssl-devel glib2-devel sqlite-devel rpm-devel file-devel libmodulemd-devel zchunk-devel python3-devel \
    && printf "libdir=/usr/lib64\nincludedir=/usr/include\n\nName: libmagic\nDescription: A file introspection library\nVersion: $(rpm -q --queryformat "%{VERSION}" file-devel)\nLibs: -L\${libdir} -lmagic\nCflags: -I\${includedir}\n" > /usr/lib64/pkgconfig/libmagic.pc
# Static build support
RUN git clone --depth 1 -b "$GIT_SOURCE_COMMIT" "$GIT_SOURCE_REPO" /opt/createrepo \
    && mkdir /opt/createrepo/build \
    && cd /opt/createrepo/build \
    && cmake -Wno-dev .. \
    && make \
    && make install

FROM $TARGET_IMAGE
COPY --from=build /opt/createrepo/ /opt/createrepo/
RUN yum install -y epel-release cmake \
    && yum install -y zchunk \
    && cd /opt/createrepo/build/src/ \
    && cmake -P cmake_install.cmake \
    && ln -sf /usr/local/lib64/libcreaterepo_c.so.0 /usr/lib64/ \
    && ln -sf /usr/local/lib64/libcreaterepo_c.so /usr/lib64/ \
    && ln -sf /usr/local/bin/createrepo_c /usr/local/bin/createrepo \
    && ln -sf /usr/local/bin/modifyrepo_c /usr/local/bin/modifyrepo \
    && ln -sf /usr/local/bin/mergerepo_c /usr/local/bin/mergerepo \
    && ln -sf /usr/local/bin/sqliterepo_c /usr/local/bin/sqliterepo \
    && cd / \
    && yum erase -y cmake \
    && yum clean all \
    && rm -rf /opt/createrepo
VOLUME ["/mnt"]
WORKDIR /mnt
CMD [ "createrepo", "--help" ]
