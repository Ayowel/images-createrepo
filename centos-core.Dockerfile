ARG BUILD_IMAGE=centos
ARG TARGET_IMAGE=$BUILD_IMAGE

FROM $TARGET_IMAGE
RUN yum install -y createrepo \
    && yum clean all
VOLUME ["/mnt"]
WORKDIR /mnt
CMD [ "createrepo", "--help" ]
