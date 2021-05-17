ARG BUILD_IMAGE=centos:7
ARG TARGET_IMAGE=$BUILD_IMAGE

FROM $BUILD_IMAGE as build
ARG LANG=C.UTF-8
ARG GIT_SOURCE_REPO="https://github.com/rpm-software-management/createrepo_c.git"
ARG GIT_SOURCE_COMMIT=master

RUN yum install -y epel-release \
    && yum install -y git make cmake gcc python3 bash-completion \
    && yum install -y bzip2-devel libcurl-devel libxml2-devel openssl-devel glib2-devel sqlite-devel rpm-devel file-devel libmodulemd-devel zchunk-devel python3-devel \
    && printf "libdir=/usr/lib64\nincludedir=/usr/include\n\nName: libmagic\nDescription: A file introspection library\nVersion: $(rpm -q --queryformat "%{VERSION}" file-devel)\nLibs: -L\${libdir} -lmagic\nCflags: -I\${includedir}\n" > /usr/lib64/pkgconfig/libmagic.pc \
    && printf "libdir=/usr/lib64\nincludedir=/usr/include/modulemd\n\nName: modulemd-2.0\nDescription: modulemd\nVersion: $(rpm -q --queryformat "%{VERSION}" libmodulemd-devel)\nLibs: -L\${libdir} -lmodulemd\nCflags: -I\${includedir}\n" > /usr/lib64/pkgconfig/modulemd-2.0.pc
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
    && yum install -y zchunk\
    && cd /opt/createrepo/build/src/ \
    && rmdir /usr/local/lib64 \
    && ln -sf /usr/lib64/ /usr/local/lib64 \
    && cmake -P cmake_install.cmake \
    && yum erase -y cmake \
    && yum clean all \
    && rm -rf /opt/createrepo

VOLUME ["/mnt"]
WORKDIR /mnt
CMD [ "createrepo", "--help" ]

