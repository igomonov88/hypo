SHELL := /bin/bash

all: sugar-api users-api metrics

keys:
	go run .sugar/cmd/sugar-admin/main.go keygen private.pem

admin:
	go run .sugar/cmd/sugar-admin/main.go --db-disable-tls=1 useradd admin@example.com gophers

migrate:
	go run .sugar/cmd/sugar-admin/main.go --db-disable-tls=1 migrate
	go run .users/cmd/users-admin/main.go --db-disable-tls=1 migrate

seed: migrate
	go run ./cmd/sugar-admin/main.go --db-disable-tls=1 seed

sugar-api:
	docker build \
		-f sugar/dockerfile.sugar-api \
		-t igorgomonov/sugar-api-amd64:1.0 \
		--build-arg PACKAGE_NAME=sugar-api \
		--build-arg VCS_REF=`git rev-parse HEAD` \
		--build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”` \
		.

users-api:
	docker build \
		-f users/dockerfile.users-api \
		-t igorgomonov/users-amd64:1.0 \
		--build-arg PACKAGE_NAME=users-api \
		--build-arg VCS_REF=`git rev-parse HEAD` \
		--build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”` \
		.

metrics:
	docker build \
		-f sugar/dockerfile.metrics \
		-t igorgomonov/sugar-metrics-amd64:1.0 \
		--build-arg PACKAGE_NAME=metrics \
		--build-arg PACKAGE_PREFIX=sidecar/ \
		--build-arg VCS_REF=`git rev-parse HEAD` \
		--build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”` \
		.

up:
	docker-compose up

down:
	docker-compose down

test:
	go test -mod=vendor ./... -count=1

clean:
	docker system prune -f

stop-all:
	docker stop $(docker ps -aq)

remove-all:
	docker rm $(docker ps -aq)

deps-reset:
	git checkout -- go.mod
	go mod tidy
	go mod vendor

deps-upgrade:
	# go get $(go list -f '{{if not (or .Main .Indirect)}}{{.Path}}{{end}}' -m all)
	go get -t -d -v ./...

deps-cleancache:
	go clean -modcac