# Usage

## With Docker

To build image:

    docker build -t blog-dev .

To run:

    docker run -it --rm -v $PWD/../..:/srv/jekyll -p 4000:4000 blog-dev

## With Docker Compose

To run:

    docker compose up

## URL

- <http://localhost:4000/>
