NAME =			diaspora
VERSION =		latest
VERSION_ALIASES =	
TITLE =			diaspora*
DESCRIPTION =		The online social world where you are in control
SOURCE_URL =		https://github.com/scaleway-community/scaleway-diaspora
# DOC_URL =		
VENDOR_URL =		https://diasporafoundation.org/

IMAGE_VOLUME_SIZE =	50G
IMAGE_BOOTSCRIPT =	stable
IMAGE_NAME =		diaspora*

## Image tools  (https://github.com/scaleway/image-tools)
all:	docker-rules.mk
docker-rules.mk:
	wget -qO - http://j.mp/scw-builder | bash
-include docker-rules.mk
