# java based image
FROM openjdk:17-jdk-alpine

# add the maintainer of the project
LABEL maintainer="Gemuese_Hasser"

# define the execution directory
ENV SERVER_DIRECTORY="/opt/server"
WORKDIR $SERVER_DIRECTORY

# define paper api query constants
# api documentation: https://papermc.io/api/docs/
ARG PAPER_API_URL="https://papermc.io/api/v2"
ARG PAPER_PROJECT="paper"
ARG PAPER_VERSION="1.17.1"

# define file location/uri constants
ARG PAPERCLIP_FILE="paperclip.jar"
ARG CACHE_DIRECTORY="cache"
ARG PATCHED_PAPER_FILENAME="$CACHE_DIRECTORY/patched_$PAPER_VERSION.jar"
ARG SERVER_FILE="paper.jar"

# obtain the java executable dynamically through the paper api
RUN set -eux \
 # add temporary build dependencies for paper download
 && apk add --no-cache --virtual .build-dependencies curl jq \
 # get the latest build for the pinned version
 && PAPER_BUILD="$(curl $PAPER_API_URL/projects/$PAPER_PROJECT/versions/$PAPER_VERSION --silent | jq '.builds[-1]')" \
 # get the download artifact from the latest build (without the json quotes)
 && PAPER_DOWNLOAD="$(curl $PAPER_API_URL/projects/$PAPER_PROJECT/versions/$PAPER_VERSION/builds/$PAPER_BUILD --silent | jq --raw-output '.downloads.application.name')" \
 # download the latest artifact of the latest build
 && curl $PAPER_API_URL/projects/$PAPER_PROJECT/versions/$PAPER_VERSION/builds/$PAPER_BUILD/downloads/$PAPER_DOWNLOAD --output "$PAPERCLIP_FILE" --silent \
 # execute the downloaded paper clip to get the patched jar
 && java -Dpaperclip.patchonly=true -jar "$PAPERCLIP_FILE" \
 # move the patched jar to the application directory
 && mv "$PATCHED_PAPER_FILENAME" "$SERVER_FILE" \
 # remove the intermediate cache directory
 && rm -r "$CACHE_DIRECTORY" \
 # remove the paperclip file that was used for patching
 && rm "$PAPERCLIP_FILE" \
 # remove the build dependencies
 && apk del .build-dependencies \
 # accept eula
 && echo "eula = true" > /opt/server/eula.txt
