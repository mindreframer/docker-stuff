# DockerFile to build docker mongoDB

## Build

You can build this docker images by command

```
docker build . -t shingara/mongodb
```

## Running

You can run this docker image by command

```
docker run -p 27017 -d shingara/mongodb mongod
```
