# RPM repository management image

Build a base image with RPM repository management capability through `createrepo_c`.
Allows to use the latest updates to createrepo, most noticeably the module management capability not available yet in official RPMs (createrepo `>0.16.1`).

## Usage

After building an image from one of the available Dockerfile (see below for instructions and details), and assuming you tagged the resulting image `ayowel/createrepo`:

```sh
docker run --rm -v "$(pwd):/mnt" ayowel/createrepo createrepo .
```

Mount the target directory into /mnt in the container.

Note that you may use `modifyrepo`, `mergerepo`, or `sqliterepo` in addition to `createrepo`.

## Build instructions

* Move to this repository's folder
* Build from the desired Dockerfile (e.g. with alpine: `docker build -f alpine.Dockerfile .`)

**Dockerfiles reference**:

* `alpine.Dockerfile`: from `alpine`, build from sources this is the most compact option (~35 MB)
* `centos.Dockerfile`: from `centos`, build from sources
* `centos-legacy.Dockerfile`: from `centos:7`, build from sources **NOT WORKING, TO BE FIXED**
* `centos-core.Dockerfile`: from `centos`, use the latest package available (you're probably better off using your own dockerfile, this is a simple yum install)

### Configuration

All builds support the following arguments:

* `TARGET_IMAGE` The image to build for, defaults to `$BUILD_IMAGE`

All builds but `centos.Dockerfile` support the following arguments:

* `BUILD_IMAGE` The base image to use to instantiate the build container
* `GIT_SOURCE_REPO` The base repository to use for createrepo's source code, defaults to `https://github.com/rpm-software-management/createrepo_c.git`
* `GIT_SOURCE_COMMIT` The commit to build from, defaults to `master`

Some builds support additionnal arguments not listed here
