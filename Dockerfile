FROM linuxgamers/arch-citra-build

ARG TAG
ARG GIT_USER
ARG GIT_EMAIL 
ARG GITHUB_TOKEN
ARG AUR_SSH_KEY

RUN useradd -ms /bin/bash linuxgamers

USER linuxgamers

RUN git clone --recursive -b "nightly-${TAG}" --depth 1 https://github.com/citra-emu/citra-nightly.git ~/citra-nightly

WORKDIR /home/linuxgamers/citra-nightly

RUN git checkout -b "${TAG}" && mkdir build && cd build && \
	cmake .. -DENABLE_FFMPEG_AUDIO_DECODER=ON && \
	make -j6

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


RUN mkdir -p ~/.ssh && \
	echo "${AUR_SSH_KEY}" | tr -d '\r' > ~/.ssh/id_rsa && chmod 700 ~/.ssh/id_rsa && \
	ssh-keyscan -H 'aur.archlinux.org' >> ~/.ssh/known_hosts && \
	eval "$(ssh-agent -s)" && \
	ssh-add ~/.ssh/id_rsa && \
	git clone ssh://aur@aur.archlinux.org/citra-nightly.git ~/citra-nightly-aur

WORKDIR /home/linuxgamers/citra-nightly-aur

RUN git config user.name "${GIT_USER}" && git config user.email "${GIT_EMAIL}" && \
	wget "https://github.com/linux-gamers/arch-citra-nightly/archive/${TAG}.tar.gz" && \
	VERSION=$(echo ${TAG} | cut -d- -f2) && \
	sed -i -E "s/pkgver=.+/pkgver=${VERSION}/" PKGBUILD && \
	SHA=$(sha512sum ${TAG}.tar.gz | grep -Eo "(\w+)\s" | cut -d" " -f1)  && \
	sed -i -E "s/sha512sums=.+/sha512sums=\(\'${SHA}\'\)/" PKGBUILD && \
	./gensrc.sh && \
	makepkg -Acsmf && \
	git commit -am "${TAG}" && \
	git push 
