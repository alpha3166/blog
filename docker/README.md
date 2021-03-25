# Usage

## Run

    docker build -t blog .
    docker run -it --rm -v $PWD/..:/srv/jekyll -p 4000:4000 blog

or

    docker-compose up

## URL

- <http://localhost:4000/>
