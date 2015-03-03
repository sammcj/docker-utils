## Docker Utils

#### [apt-settings.sh](https://raw.githubusercontent.com/sammcj/docker-utils/master/apt-settings.sh)

* Sets apt mirrors (default is AU)
* Enables contrib and non-free repos

###### Usage

Near the top of your Dockerfile:
```
RUN apt-get update && apt-get -y install curl && \
    curl -s https://raw.githubusercontent.com/sammcj/docker-utils/master/apt-settings.sh | sh
```
