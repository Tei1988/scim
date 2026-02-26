IMAGE="scim"
REPOSITORY_URL="tei1988"
#ARCHITECTURE="linux/arm64"
ARCHITECTURE="linux/amd64"
TAG="latest"

all:
	docker buildx build \
	--platform "linux/amd64,linux/arm64" \
	. \
	-t ${REPOSITORY_URL}/${IMAGE}:${TAG} \
	--push

develop:
	docker run --pull always \
		-e PORT=8080 \
		-e FIRESTORE_GCLOUD_PROJECT="is-playground" \
		-e GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json" \
		--rm \
		-p 8080:8080 \
		-v ${PWD}/.config/gcloud:/root/.config/gcloud:ro \
		${REPOSITORY_URL}/${IMAGE}:${TAG}
