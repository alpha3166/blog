# Usage

## With Podman/Docker

To build image:

    podman build -t blog .

To run:

    podman run -it --rm -v $PWD/..:/srv/jekyll -p 4000:4000 -e JEKYLL_ROOTLESS=1 blog

## With Podman/Docker Compose

To run:

    podman compose up -d

To stop:

    podman compose down

## URL

- <http://localhost:4000/>
