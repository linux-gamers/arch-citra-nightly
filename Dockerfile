FROM linuxgamers/arch-citra-build

ARG TAG
ARG GIT_USER
ARG GIT_EMAIL 
ARG GITHUB_TOKEN

RUN useradd -ms /bin/bash linuxgamers

USER linuxgamers

RUN git clone --recursive -b "nightly-${TAG}" --depth 1 https://github.com/citra-emu/citra-nightly.git ~/citra-nightly

WORKDIR /home/linuxgamers/citra-nightly

RUN git checkout -b "${TAG}" && mkdir build && cd build && \
	cmake .. -DENABLE_FFMPEG_AUDIO_DECODER=ON && \
	make -j4

WORKDIR /home/linuxgamers

RUN git clone https://${GITHUB_TOKEN}@github.com/linux-gamers/arch-citra-nightly.git ~/arch-citra-nightly && \
	cd arch-citra-nightly && \
    /bin/cp ~/citra-nightly/build/bin/Release/citra . && \
	/bin/cp ~/citra-nightly/build/bin/Release/citra-qt . && \
	/bin/cp ~/citra-nightly/build/bin/Release/citra-room . && \
	/bin/cp ~/citra-nightly/dist/citra.desktop . && \
	/bin/cp ~/citra-nightly/dist/citra.svg . && \
	git config user.name "${GIT_USER}" && \
	git config user.email "${GIT_EMAIL}" && \
	git add . && \
	git commit -m "[RELEASE ${TAG}]" && \
	git push -q https://${GITHUB_TOKEN}@github.com/linux-gamers/arch-citra-nightly.git master

RUN curl -X POST -H "Content-Type: application/json" -d "{ \
		\"tag_name\": \"${TAG}\", \
  		\"target_commitish\": \"master\", \
  		\"name\": \"${TAG}\", \
  		\"draft\": false, \
  		\"prerelease\": false \
	}" https://${GITHUB_TOKEN}@api.github.com/repos/linux-gamers/arch-citra-nightly/releases
